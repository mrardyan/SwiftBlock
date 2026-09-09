class Swiftblock < Formula
  desc "Production-ready iOS project generator and scaffolding CLI"
  homepage "https://github.com/mrardyan/swiftblock"
  url "https://github.com/mrardyan/swiftblock/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license "MIT"

  depends_on :xcode => ["15.0", :build]
  depends_on :macos => :monterey

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/swiftblock"
    (share/"swiftblock").install "Blocks"
  end

  test do
    system "#{bin}/swiftblock", "--help"
  end
end
