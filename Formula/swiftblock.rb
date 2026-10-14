class Swiftblock < Formula
  desc "Modular Scaffolding & Component Block CLI Engine for iOS"
  homepage "https://github.com/mrardyan/SwiftBlock"
  url "https://github.com/mrardyan/SwiftBlock/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "REPLACE_WITH_SHA256_HASH_OF_RELEASE_TAR_GZ"
  license "MIT"

  depends_on :xcode => ["14.0", :build]

  def install
    # 1. Compile release executable binary
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/swiftblock"

    # 2. Install template baseplates and brick building blocks
    (share/"swiftblock/Baseplates").install Dir["Baseplates/*"]
    (share/"swiftblock/Bricks").install Dir["Bricks/*"]
  end

  test do
    system "#{bin}/swiftblock", "--help"
  end
end
