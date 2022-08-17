FROM docker-registry.l-its.de/archlinux-base:latest

RUN pacman -Syu --needed --noconfirm docker-compose && \
    pacman -Scc
