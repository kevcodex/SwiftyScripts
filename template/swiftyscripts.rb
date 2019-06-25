# Documentation: https://docs.brew.sh/Formula-Cookbook
#                http://www.rubydoc.info/github/Homebrew/brew/master/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Swiftyscripts < Formula
    desc ""
    homepage "https://bitbucket.org/kevcodex"
    url "https://bitbucket.org/kevcodex/teammergeautomation/raw/5b98def4715eadefae6752e5925c44c6c13b55cf/releases/swiftyscripts.tar.gz"
    version "5.2"
    sha256 "7c684a67436544cd8bfb72e7ce20b761a2c1720d2611f0ee4c0c0fc5d1b7a2d0"
    # depends_on "cmake" => :build
  
    def install
      bin.install "SwiftyScripts"
    end
  
    test do
      system "false"
    end
  end
  
