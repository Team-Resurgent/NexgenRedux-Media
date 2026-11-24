<h1 align="center">NexgenRedux-Media</h1>

<p align="center"><b>An example game for Nexgen Redux, written in AngelScript</b></p>

<p align="center">
  <a href="https://discord.gg/VcdSfajQGK"><img src="https://img.shields.io/badge/chat-on%20discord-7289da.svg?logo=discord" alt="Discord"></a>
</p>

<p align="center">
  <a href="https://ko-fi.com/J3J7L5UMN"><img src="https://ko-fi.com/img/githubbutton_sm.svg" alt="ko-fi"></a>
  <a href="https://www.patreon.com/teamresurgent"><img src="https://img.shields.io/badge/Patreon-F96854?style=for-the-badge&logo=patreon&logoColor=white" alt="Patreon"></a>
</p>

A shooter for the first [Nexgen Redux](https://github.com/Team-Resurgent/NexgenRedux) engine. It shows sprites, layered
scrolling backgrounds, text, collisions, music and sound, and input from a gamepad, keyboard or mouse.

<p align="center">
  <img src="screenshots/shooter-art.png" alt="Art from the shooter" width="80%">
</p>
<p align="center"><sub>Art from the game</sub></p>

## Layout

| Path | What it is |
|---|---|
| `Shooter/main.as` | The whole game |
| `Shooter/Asset/images` | Ships, bullets and backgrounds |
| `Shooter/Asset/fonts` | Bitmap fonts, and `freesans.sfn` |
| `Shooter/Asset/Audio`, `Shooter/Audio` | Music and sound |

## Running it

Copy the contents of `Shooter` into the media folder of a built Nexgen Redux, so that `main.as` is at its top, and start it.
The calls it uses are described in [NexgenRedux-Docs](https://team-resurgent.github.io/NexgenRedux-Docs/).

Some of the ships and backgrounds also appear in the new engine's showcase, in
[`engine/media/showcase`](https://github.com/Team-Resurgent/NexgenRedux/tree/main/engine/media/showcase).

## Related repositories

| Repository | What it is |
|---|---|
| [NexgenRedux](https://github.com/Team-Resurgent/NexgenRedux) | The engine |
| [NexgenRedux-Docs](https://github.com/Team-Resurgent/NexgenRedux-Docs) | The script reference |
