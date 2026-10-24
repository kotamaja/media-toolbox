# media-toolbox

A lightweight Docker toolbox to:
- download videos and audio from YouTube (and other platforms supported by yt-dlp)
- download complete playlists and YouTube channels
- convert videos to animated GIFs
- use everything via simple CLI commands (no server, no UI)

This image is designed as a **personal, deterministic CLI toolbox**.

---

## Included tools

- `yt-dlp` (official standalone binary, no Python required)
- `ffmpeg`
- `deno` (JavaScript runtime used by yt-dlp for YouTube challenge solving)
- helper shell scripts

Available commands:
- `ydl-video` – download a video (best quality)
- `ydl-audio` – download audio (best quality, no re-encoding when possible)
- `ydl-audio-mp3` – download audio as MP3 (re-encoded, maximum compatibility)
- `ydl-playlist` – download a full playlist (with resume support)
- `ydl-channel` – download all regular videos from a YouTube channel (with resume support)
- `video-to-gif` – convert a local video to an animated GIF

---

## File naming convention

Individual downloaded files follow this format:

```text
<channel>_<title>_[<extractor>-<id>].<ext>
+```

Example:

```text
ARTE_NARCOTRAFIC_La_FACE_CACHEE_[youtube-y8iiHrN3mhU].mkv
```

Characteristics:
- no spaces (underscores only)
- unique (video ID included)
- traceable (platform + channel)
- safe for NAS, scripts, CI, and filesystems

### Playlist layout

Playlist videos are stored in a directory named after the playlist and numbered according to their position:

```text
<playlist_title>/<index>-<channel>_<title>_[<extractor>-<id>].<ext>
```

Example:

```text
My_Playlist/
001-Channel_First_Video_[youtube-XXXXXXXXXXX].mkv
002-Channel_Second_Video_[youtube-YYYYYYYYYYY].mkv
```

### Channel layout

Channel videos are stored in a directory named after the channel and prefixed with their publication date:

```text
<channel>/<YYYYMMDD>-<channel>_<title>_[<extractor>-<id>].<ext>
```

Example:

```text
Nick-E.com/
20210602-Nick-E.com_Deadbug_Level_1_Static_Hold_[youtube-2hHtyhsYDBA].mkv
20210615-Nick-E.com_Another_Exercise_[youtube-XXXXXXXXXXX].mkv
```

Using the publication date instead of an index keeps filenames stable when new videos are added to the channel.

---

## Build the image

```bash
docker build \
  --build-arg YTDLP_VERSION=2026.01.31 \
  -t media-toolbox .
```

---

## Usage

⚠️ **Important**

To ensure downloaded files are owned by the local user (not `root`), always run the container with the host UID/GID.

### Download a video

```bash
docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v "$PWD/media:/work" \
  media-toolbox \
  ydl-video "https://www.youtube.com/watch?v=XXXXXXXX"
```

### Download audio (best quality)

```bash
docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v "$PWD/media:/work" \
  media-toolbox \
  ydl-audio "https://www.youtube.com/watch?v=XXXXXXXX"
```

### Download audio as MP3

```bash
docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v "$PWD/media:/work" \
  media-toolbox \
  ydl-audio-mp3 "https://www.youtube.com/watch?v=XXXXXXXX"
```

### Download a full playlist (with resume support)

```bash
docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v "$PWD/media:/work" \
  media-toolbox \
  ydl-playlist "https://www.youtube.com/playlist?list=XXXXXXXX"
```

A `.ydl-archive.txt` file is created in `/work` to prevent re-downloading already processed videos.

### Download a YouTube channel (with resume support)

```bash
docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v "$PWD/media:/work" \
  media-toolbox \
  ydl-channel "https://www.youtube.com/@CHANNEL/videos"
```

Prefer using the channel's `/videos` URL:

```text
https://www.youtube.com/@CHANNEL/videos
```

This limits the download to the channel's regular videos instead of automatically including other sections such as Shorts or live streams.

Videos are stored in a directory named after the channel and ordered by publication date:

```text
Channel_Name/
20210602-Channel_Name_Video_Title_[youtube-XXXXXXXXXXX].mkv
20210718-Channel_Name_Another_Video_[youtube-YYYYYYYYYYY].mkv
```

A `.ydl-channel-archive.txt` file is created in `/work` to prevent re-downloading already processed videos.

This means the command can safely be executed again later to retrieve newly published videos:

```bash
docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v "$PWD/media:/work" \
  media-toolbox \
  ydl-channel "https://www.youtube.com/@CHANNEL/videos"
```

Videos already present in the archive will be skipped.

---

## Video → GIF conversion

```bash
docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v "$PWD/media:/work" \
  media-toolbox \
  video-to-gif /work/input.mp4 /work/output.gif 10 5
```

Arguments:
- `10` – start time (seconds)
- `5` – duration (seconds)

The start time must be within the duration of the source video.

For example, for a 3.3-second video:

```bash
docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v "$PWD/media:/work" \
  media-toolbox \
  video-to-gif /work/input.mkv /work/output.gif 0 3
```

Optional environment variables:

```bash
FPS=20 WIDTH=720
```

---

## Shell alias (optional)

```bash
alias media-toolbox='docker run --rm -u "$(id -u):$(id -g)" -v "$PWD/media:/work" media-toolbox'
```

Then simply run:

```bash
media-toolbox ydl-video "https://www.youtube.com/watch?v=XXXXXXXX"
```

For a playlist:

```bash
media-toolbox ydl-playlist "https://www.youtube.com/playlist?list=XXXXXXXX"
```

For a channel:

```bash
media-toolbox ydl-channel "https://www.youtube.com/@CHANNEL/videos"
```

---

## Download archives

The toolbox uses yt-dlp archive files to remember which videos have already been successfully downloaded.

Playlist downloads use:

```text
/work/.ydl-archive.txt
```

Channel downloads use:

```text
/work/.ydl-channel-archive.txt
```

Because `/work` is mounted from the host, these files persist when the Docker container exits.

Do not delete an archive unless you intentionally want yt-dlp to consider previously downloaded videos again.

---

## Notes

- The image does **not** include Python
- `yt-dlp` is used as an official standalone binary
- Deno is included as the JavaScript runtime used by yt-dlp for YouTube
- Updating yt-dlp requires rebuilding the image with a new version
- Playlist ordering uses the playlist index
- Channel ordering uses the original publication date (`YYYYMMDD`)
- Channel URLs ending in `/videos` are recommended when only regular videos should be downloaded

---

## License

Personal use.