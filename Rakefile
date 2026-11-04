# Tasks for building, installing, and releasing KEXP Now Playing.
# The heavy lifting lives in scripts/; these tasks wrap them.
#
#   rake build            # compile + ad-hoc sign (Release; CONFIG=Debug to override)
#   rake install          # quit any installed copy, build, install to /Applications, launch
#   rake package          # build dist/KEXP-Now-Playing-<version>.dmg
#   rake release          # package and publish a GitHub release for the current version

VERSION = File.read("project.yml")[/^\s*MARKETING_VERSION:\s*"?([^"\s]+)"?/, 1] or abort "MARKETING_VERSION not found in project.yml"
TAG = "v#{VERSION}"
DMG = "dist/KEXP-Now-Playing-#{VERSION}.dmg"
INSTALLED_APPS = ["/Applications/KEXP Now Playing.app", File.expand_path("~/Applications/KEXP Now Playing.app")]

task default: :build

desc "Build the app and widget (Release; set CONFIG=Debug to override) without installing"
task :build do
  sh "./scripts/build.sh", "--no-install"
end

desc "Quit any installed copy, then build, install to /Applications, and launch"
task :install do
  if INSTALLED_APPS.any? { |app| File.directory?(app) }
    sh "open", "kexpnowplaying://quit"
    # Give it a moment to exit; build.sh force-kills anything still running.
    10.times { break unless system("pgrep", "-x", "KEXP Now Playing", out: File::NULL); sleep 0.5 }
  end
  sh "./scripts/build.sh", "--open"
end

desc "Package a Release build as #{DMG}"
task :package do
  sh "./scripts/package.sh"
end

desc "Package and publish GitHub release #{TAG}"
task :release do
  abort "Working tree is dirty; commit or stash first." unless `git status --porcelain`.strip.empty?
  sh "git fetch --quiet origin"
  abort "HEAD isn't pushed to origin; push first." unless `git branch -r --contains HEAD`.strip != ""
  if system("gh", "release", "view", TAG, out: File::NULL, err: File::NULL)
    abort "Release #{TAG} already exists; bump MARKETING_VERSION in project.yml."
  end

  Rake::Task[:package].invoke
  sh "gh", "release", "create", TAG, DMG, "--title", TAG, "--generate-notes"
end
