#!/usr/bin/env python3
"""Upload the release AAB once, assign it to one or more Play tracks
(default: internal) as a *completed* release with localized notes from the
fastlane changelogs, and commit the edit. (Ported from knabberfuchs.)

    python3 tool/play_upload_aab.py [track ...]

Nothing stays in Draft and there is no publish step in the Console afterwards:
committing a 'completed' release rolls the build out to that track's testers
right away (production would go fully live, subject to Play review). The
commit passes changesNotSentForReview=True where the API allows it, falling
back to a plain commit otherwise.
"""
import os
import re
import socket
import sys

socket.setdefaulttimeout(600)  # large AAB upload — don't read-timeout mid-chunk

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload

KEY = 'fastlane/play-store-key.json'
PKG = 'ch.fuchsnest.knobelfuchs'
AAB = 'build/app/outputs/bundle/release/app-release.aab'
META = 'fastlane/metadata/android'
# One or more tracks (the AAB is uploaded once, then assigned to each). Track
# names with spaces must be quoted as a single argv entry by the caller.
TRACKS = sys.argv[1:] if len(sys.argv) > 1 else ['internal']
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']


def release_name():
    """"0.2.3 (5)" from pubspec — otherwise Play names every release after
    the first upload it ever saw (Console feedback 2026-07-14)."""
    try:
        with open('pubspec.yaml', encoding='utf-8') as f:
            m = re.search(r'^version:\s*(\S+)', f.read(), re.M)
        version, _, build = m.group(1).partition('+')
        return f'{version} ({build})' if build else version
    except Exception:
        return None


def release_notes(version_code):
    notes = []
    for loc in sorted(os.listdir(META)):
        p = os.path.join(META, loc, 'changelogs', f'{version_code}.txt')
        if os.path.isfile(p):
            with open(p, encoding='utf-8') as f:
                notes.append({'language': loc, 'text': f.read().strip()})
    return notes


def main():
    creds = service_account.Credentials.from_service_account_file(
        KEY, scopes=SCOPES)
    svc = build('androidpublisher', 'v3', credentials=creds,
                cache_discovery=False)
    edit_id = svc.edits().insert(packageName=PKG, body={}).execute()['id']
    print('edit %s — uploading %s (%.0f MB)' % (
        edit_id, AAB, os.path.getsize(AAB) / 1e6))
    try:
        req = svc.edits().bundles().upload(
            packageName=PKG, editId=edit_id,
            media_body=MediaFileUpload(
                AAB, mimetype='application/octet-stream', resumable=True,
                chunksize=10 * 1024 * 1024))
        resp = None
        while resp is None:
            status, resp = req.next_chunk(num_retries=5)
            if status:
                print('  %d%%' % int(status.progress() * 100))
        vc = resp['versionCode']
        print('uploaded versionCode %s' % vc)

        notes = release_notes(vc)

        name = release_name()

        def assign(status):
            for track in TRACKS:
                release = {'versionCodes': [str(vc)],
                           'status': status,
                           'releaseNotes': notes}
                if name:
                    release['name'] = name
                svc.edits().tracks().update(
                    packageName=PKG, editId=edit_id, track=track,
                    body={'track': track, 'releases': [release]}
                ).execute()
                print('assigned to track "%s" (%s, name=%s)'
                      % (track, status, name or 'auto'))

        def commit():
            try:
                svc.edits().commit(packageName=PKG, editId=edit_id,
                                   changesNotSentForReview=True).execute()
            except HttpError as e:
                if e.resp.status == 400 and 'changesNotSentForReview' in str(
                        e._get_reason()):
                    svc.edits().commit(packageName=PKG,
                                       editId=edit_id).execute()
                else:
                    raise

        assign('completed')
        try:
            commit()
        except HttpError as e:
            # A brand-new ("draft") app accepts only DRAFT releases until its
            # first Console rollout — stage as draft and roll out manually
            # once; every later release commits as completed like knabberfuchs.
            if e.resp.status == 400 and 'draft app' in str(e._get_reason()):
                print('draft app — staging as DRAFT release instead; '
                      'roll it out once in the Play Console')
                assign('draft')
                commit()
            else:
                raise
        print('committed — release staged on: %s' % ', '.join(
            '"%s"' % t for t in TRACKS))
    except HttpError as e:
        try:
            svc.edits().delete(packageName=PKG, editId=edit_id).execute()
        except HttpError:
            pass
        print('API ERROR %s:' % e.resp.status, e._get_reason(), file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
