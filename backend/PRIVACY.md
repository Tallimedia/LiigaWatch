# FILiigaWatch — Privacy Policy

_Effective 2026-09-24. Contact: iot@tallimedia.com_

This policy explains what the app stores and why. It is run by a private
individual, not a company, and is not affiliated with Jääkiekon SM-liiga Oy
("Liiga").

**The short version: the app has no account, and nothing about you is stored.**

## What is stored

Nothing that identifies you.

There is no sign-in, no account and no pairing step. The app never asks for
your name, email, or any credential, and there is nothing to revoke.

Your chosen favourite team and update-frequency setting are held **on your
own watch only**, in Connect IQ's on-device storage. They are never sent to
the backend and never leave the watch.

## What is sent when you open the app

To fetch scores or the league table, the watch asks the backend for them.
That request carries only a date (for scores) or a season year (for the
table) — nothing that identifies you or your watch. Two people asking for
the same day send identical requests.

## Location

**The app does not use your watch's GPS.** It does not request the
Positioning permission and could not read your location even if it tried —
there is no concept of location anywhere in what the app shows.

## Where it runs

On a self-hosted server operated by the app author. It keeps a short-lived
cache of liiga.fi responses — seconds during a live game, minutes otherwise
— so that repeated requests do not hammer liiga.fi's service. That cache is
keyed on the date or season requested, never on anything about who asked.

No analytics, no advertising, no tracking of any kind.

## Third parties

- **Liiga.fi** provides the scores and standings data, through its public
  API. The backend fetches it; your watch never contacts liiga.fi directly.
- **Garmin's Connect IQ platform** relays requests between your watch and
  the backend, and is subject to Garmin's own terms and privacy policy.

## Deleting your data

There is nothing held about you to delete. Removing the app from your watch
removes the settings with it.
