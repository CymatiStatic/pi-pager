# Documentation: https://docs.brew.sh/Formula-Cookbook
# typed: false
# frozen_string_literal: true

class PiPager < Formula
  desc "Cross-channel alerts for agentic AI workflows (sound, ntfy, Discord, Slack, Telegram, Pushover)"
  homepage "https://github.com/CymatiStatic/pi-pager"
  url "https://github.com/CymatiStatic/pi-pager/archive/refs/tags/v0.3.0.tar.gz"
  # Placeholder sha256 — auto-filled by `brew create` or `brew fetch --build-from-source`
  sha256 "REPLACE_WITH_SHA256_OF_v0.3.0.tar.gz"
  license "MIT"
  head "https://github.com/CymatiStatic/pi-pager.git", branch: "main"

  depends_on "curl"
  depends_on "jq" => :recommended

  def install
    libexec.install "scripts/notify.sh", "scripts/inbox.ps1", "scripts/notify.ps1",
                    "scripts/inbox-daemon.ps1", "scripts/notify.config.example.json"
    bin.install_symlink libexec/"notify.sh" => "pi-pager"

    (prefix/"examples").install Dir["examples/*"]
    prefix.install "README.md", "LICENSE"
  end

  def post_install
    data_dir = Pathname.new("#{ENV["HOME"]}/.pi-pager")
    data_dir.mkpath unless data_dir.exist?
    cfg = data_dir/"notify.config.json"
    unless cfg.exist?
      require "securerandom"
      topic = "pi-pager-#{SecureRandom.hex(8)}"
      template = (libexec/"notify.config.example.json").read
      cfg.write(template.sub("REPLACE_WITH_RANDOM_TOPIC_OR_RUN_INSTALL", topic))
      ohai "Generated pi-pager config at #{cfg}"
      ohai "Your ntfy topic: #{topic}"
      ohai "Install ntfy app on your phone and subscribe to that topic."
    end
  end

  def caveats
    <<~EOS
      pi-pager is installed as `pi-pager`. Try:
        pi-pager --type done --message "Hello from Homebrew"

      Your ntfy topic is in ~/.pi-pager/notify.config.json

      Install the ntfy app on your phone:
        iOS:     https://apps.apple.com/us/app/ntfy/id1625396347
        Android: https://play.google.com/store/apps/details?id=io.heckel.ntfy
    EOS
  end

  test do
    assert_match "Agent", shell_output("#{bin}/pi-pager --help 2>&1", 0).chomp
  end
end
