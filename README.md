<h1 align="center">NexgenRedux-Media</h1>

<p align="center"><b>The demos of Nexgen Redux: one script each</b></p>

<p align="center">
  <a href="https://team-resurgent.github.io/NexgenRedux-Docs/demos.html"><img src="https://img.shields.io/badge/docs-online-brightgreen.svg" alt="Read online"></a>
  <a href="https://discord.gg/VcdSfajQGK"><img src="https://img.shields.io/badge/chat-on%20discord-7289da.svg?logo=discord" alt="Discord"></a>
</p>

<p align="center">
  <a href="https://ko-fi.com/J3J7L5UMN"><img src="https://ko-fi.com/img/githubbutton_sm.svg" alt="ko-fi"></a>
  <a href="https://www.patreon.com/teamresurgent"><img src="https://img.shields.io/badge/Patreon-F96854?style=for-the-badge&logo=patreon&logoColor=white" alt="Patreon"></a>
</p>

Everything that the [Nexgen Redux](https://github.com/Team-Resurgent/NexgenRedux) app shows, on every platform. To play them, get a
[release](https://github.com/Team-Resurgent/NexgenRedux/releases/latest); to read their scripts, see the
[demos page](https://team-resurgent.github.io/NexgenRedux-Docs/demos.html).

<p align="center">
  <img src="screenshots/explore.png" alt="Island" width="32%">
  <img src="screenshots/dashboard.png" alt="Dashboard" width="32%">
  <img src="screenshots/blades.png" alt="Blades" width="32%">
</p>
<p align="center">
  <img src="screenshots/shooter.png" alt="Shooter" width="32%">
  <img src="screenshots/platformer.png" alt="Platformer" width="32%">
  <img src="screenshots/physics.png" alt="Physics" width="32%">
</p>
<p align="center">
  <img src="screenshots/runes.png" alt="Rune shift" width="32%">
  <img src="screenshots/music.png" alt="Music" width="32%">
  <img src="screenshots/particles.png" alt="Particles" width="32%">
</p>

## Layout

| Path | What it is |
|---|---|
| `media/showcase/<name>/screen.json` | A demo's title, description and place in the menu, and what to press when it is shown off |
| `media/showcase/<name>/main.as` | Its script |
| `media/showcase/<name>/asset` | Its own pictures, sounds and scene files |
| `media/global` | Fonts, sounds and models that demos share |

Add a folder and it appears in the menu. How to write one is in the
[guide](https://team-resurgent.github.io/NexgenRedux-Docs/guide.html).

The sounds, music and test pictures are made by `engine/tools/make_media.py` in NexgenRedux, and the models by `make_models.py`.
The Dashboard's models and the Blades' pictures are from the first engine's skins.

## Related repositories

| Repository | What it is |
|---|---|
| [NexgenRedux](https://github.com/Team-Resurgent/NexgenRedux) | The engine |
| [NexgenRedux-Docs](https://github.com/Team-Resurgent/NexgenRedux-Docs) | The documentation site |
