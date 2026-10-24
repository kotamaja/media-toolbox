# syntax=docker/dockerfile:1
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

# Ensure a writable HOME for non-root runs (yt-dlp cache, temp files, etc.)
ENV HOME=/tmp/home
RUN mkdir -p /tmp/home/.cache /tmp/home/.config && chmod -R 777 /tmp/home

# ---- system tools ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    ffmpeg \
    bash \
    atomicparsley \
  && rm -rf /var/lib/apt/lists/*

# ---- Deno (JS runtime for YouTube extraction) ----
ARG DENO_VERSION=2.6.7

RUN curl -fL "https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/deno-x86_64-unknown-linux-gnu.zip" \
      -o /tmp/deno.zip \
  && apt-get update && apt-get install -y --no-install-recommends unzip \
  && unzip /tmp/deno.zip -d /usr/local/bin \
  && chmod +x /usr/local/bin/deno \
  && rm -f /tmp/deno.zip \
  && apt-get purge -y unzip \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/* \
  && deno --version

# ---- yt-dlp standalone binary ----
ARG YTDLP_VERSION=2026.01.31

RUN curl -fL \
      "https://github.com/yt-dlp/yt-dlp/releases/download/${YTDLP_VERSION}/yt-dlp_linux" \
      -o /usr/local/bin/yt-dlp \
  && chmod +x /usr/local/bin/yt-dlp \
  && yt-dlp --version

# ---- workspace ----
WORKDIR /work

# ---- CLI helper scripts ----
COPY bin/ /usr/local/bin/
RUN chmod +x \
    /usr/local/bin/ydl-video \
    /usr/local/bin/ydl-channel \
    /usr/local/bin/ydl-audio \
    /usr/local/bin/ydl-audio-mp3 \
    /usr/local/bin/ydl-playlist \
    /usr/local/bin/video-to-gif

# ---- default ----
CMD ["bash", "-lc", "echo 'Toolbox ready:'; echo ' - ydl-video'; echo ' - ydl-audio'; echo ' - ydl-audio-mp3'; echo ' - ydl-playlist'; echo ' - video-to-gif'; echo 'Workdir: /work (mount a volume)'; bash"]
