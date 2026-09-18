

FROM ubuntu:24.04

RUN userdel -r ubuntu 2>/dev/null || true
RUN sed -i 's/^Components: .*/Components: main restricted universe/' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || true

RUN apt-get update \
    && apt-get install -y \
        ca-certificates gnupg apt-transport-https software-properties-common \
        openssh-server \
        curl wget \
        iproute2 iputils-ping net-tools dnsutils traceroute whois telnet nmap \
        vim nano micro \
        htop btop ncdu neofetch \
        tmux screen less tree bat ripgrep fd-find jq zsh \
        unzip zip tar gzip bzip2 xz-utils p7zip-full \
        git build-essential cmake pkg-config autoconf automake libtool gcc g++ \
        python3 python3-pip python3-venv python3-dev \
        nodejs npm \
        locales ncurses-term language-pack-en language-pack-fa \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && mkdir -p /run/sshd \
    && chmod 755 /run/sshd \
    && ssh-keygen -A \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    # Enable root login / فعال کردن ورود root
    && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Generate English and Persian locales / تولید لوکِیل‌های انگلیسی و فارسی
RUN locale-gen en_US.UTF-8 fa_IR.UTF-8

# ARA TM welcome banner shown on interactive SSH login
# بنر خوش‌آمد ARA TM که هنگام ورود تعاملی SSH نمایش داده می‌شود
COPY ara-welcome.sh /etc/profile.d/ara-welcome.sh
RUN chmod +x /etc/profile.d/ara-welcome.sh

# Set locale and terminal environment / تنظیم لوکِیل و محیط ترمینال
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV TERM=xterm-256color


ARG ANTHROPIC_AUTH_TOKEN=""
COPY claude-settings.json /root/.claude/settings.json
RUN sed -i "s|__ANTHROPIC_AUTH_TOKEN__|${ANTHROPIC_AUTH_TOKEN}|g" /root/.claude/settings.json


RUN npm install -g @anthropic-ai/claude-code

# Copy ssh user config to configure the user's password and authorized keys
# کپی اسکریپت تنظیم کاربر SSH برای پیکربندی رمز عبور و کلیدهای مجاز
COPY ssh-user-config.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/ssh-user-config.sh

# Copy the "cl" helper command (opens a tmux session running Claude Code) and
# expose it under both "cl" and "زم".
# کپی دستور کمکی "cl" (باز کردن نشست tmux با Claude Code) و در دسترس قرار دادن
# آن با نام‌های "cl" و "زم".
COPY cl /usr/local/bin/cl
RUN chmod +x /usr/local/bin/cl \
    && ln -sf /usr/local/bin/cl /usr/local/bin/زم

# Copy the "usage" command (Railway trial credit + uptime monitor)
# کپی دستور «usage» (مانیتور اعتبار تریال و زمان بیداری Railway)
COPY usage /usr/local/bin/usage
RUN chmod +x /usr/local/bin/usage

# Copy the "src-sync" command (/root/src ⇄ private GitHub repo for persistence)
# کپی دستور «src-sync» (همگام‌سازی پوشه src با مخزن خصوصی GitHub برای پایداری داده‌ها)
COPY src-sync.sh /usr/local/bin/src-sync
RUN chmod +x /usr/local/bin/src-sync \
    && mkdir -p /root/src

# Expose port 22 (default SSH port) / باز کردن پورت ۲۲ (پورت پیش‌فرض SSH)
EXPOSE 22

# Start the SSH server / راه‌اندازی سرور SSH
CMD ["/usr/local/bin/ssh-user-config.sh"]
