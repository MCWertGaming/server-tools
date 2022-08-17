FROM archlinux/base:latest

RUN pacman -Rns --noconfirm systemd less gzip sed && \
    pacman -Syu --needed --noconfirm && \
    # pacman -Qtdq | pacman -Rns - && \
    pacman -Scc
