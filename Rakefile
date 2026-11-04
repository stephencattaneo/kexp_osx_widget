# Tasks for building, installing, and releasing KEXP Now Playing.
# The heavy lifting lives in scripts/; these tasks wrap them.
#
#   rake build            # compile + ad-hoc sign (Release; CONFIG=Debug to override)
#   rake install          # quit any installed copy, build, install to /Applications, launch
#   rake package          # build dist/KEXP-Now-Playing-<version>.dmg
#   rake release          # bump version, build DMG, commit, tag, push, publish GitHub release
#   rake "release[2.0]"   # ...releasing a specific version

VERSION = File.read("project.yml")[/^\s*MARKETING_VERSION:\s*"?([^"\s]+)"?/, 1] or abort "MARKETING_VERSION not found in project.yml"
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

desc "Bump the version, build the DMG, commit, tag, push, and publish the GitHub release " \
     "(next minor version by default, or e.g. rake \"release[1.5]\")"
task :release, [:version] do |_, args|
  # Preflight: everything that could stop the release is checked before anything changes.
  branch = `git rev-parse --abbrev-ref HEAD`.strip
  abort "Release from main (currently on #{branch})." unless branch == "main"
  abort "Working tree is dirty; commit or stash first." unless `git status --porcelain`.strip.empty?
  sh "git fetch --quiet origin main"
  abort "main is behind origin/main; pull first." unless `git rev-list --count HEAD..origin/main`.strip == "0"
  abort "gh isn't logged in; run: gh auth login" unless system("gh auth status", out: File::NULL, err: File::NULL)

  major, minor = VERSION.split(".").map(&:to_i)
  version = args[:version] || "#{major}.#{minor + 1}"
  abort "Version must look like 1.4 (got #{version})." unless version.match?(/\A\d+\.\d+(\.\d+)?\z/)
  tag = "v#{version}"
  abort "Tag #{tag} already exists." if system("git rev-parse -q --verify refs/tags/#{tag}", out: File::NULL)
  if system("gh", "release", "view", tag, out: File::NULL, err: File::NULL)
    abort "GitHub release #{tag} already exists."
  end

  yml = File.read("project.yml")
  build = yml[/^\s*CURRENT_PROJECT_VERSION:\s*"?(\d+)"?/, 1].to_i + 1
  puts "Releasing #{tag} (build #{build})"

  # 1. Bump the version.
  File.write("project.yml", yml
    .sub(/^(\s*MARKETING_VERSION:\s*).*$/) { "#{$1}\"#{version}\"" }
    .sub(/^(\s*CURRENT_PROJECT_VERSION:\s*).*$/) { "#{$1}\"#{build}\"" })

  # 2. Build the DMG before committing, so a failed build leaves nothing behind.
  begin
    sh "./scripts/package.sh"
  rescue
    sh "git checkout -- project.yml"
    raise
  end
  dmg = "dist/KEXP-Now-Playing-#{version}.dmg"

  # 3. Commit, tag, and push.
  sh "git", "commit", "--quiet", "-m", "Release #{tag}", "project.yml"
  sh "git", "tag", "-a", tag, "-m", tag
  sh "git", "push", "--quiet", "--atomic", "origin", "main", tag

  # 4. Publish the GitHub release with the DMG.
  sh "gh", "release", "create", tag, dmg, "--title", tag, "--generate-notes", "--verify-tag"
  puts "Released #{tag}"
end
