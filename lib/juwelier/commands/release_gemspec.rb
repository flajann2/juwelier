require 'pathname'

class Juwelier
  module Commands
    class ReleaseGemspec
      attr_accessor :gemspec, :version, :repo, :output, :gemspec_helper, :base_dir

      def initialize(attributes = {})
        self.output = $stdout

        attributes.each_pair do |key, value|
          send("#{key}=", value)
        end
      end

      def run(args = {})
        remote = args[:remote] || 'origin'
        branch = args[:branch] || 'master'
        local_branch = args[:local_branch] || branch
        remote_branch = args[:remote_branch] || branch

        unless clean_staging_area?
          system "git status"
          raise "Unclean staging area! Be sure to commit or .gitignore everything first. See `git status` above."
        end

        repo.checkout(local_branch)

        regenerate_gemspec!
        commit_gemspec! if gemspec_changed?

        output.puts "Pushing #{local_branch} to #{remote}"
        repo.push(remote, "#{local_branch}:#{remote_branch}")
      end

      def clean_staging_area?
        # surprisingly simpler than ruby-git
        `git ls-files --deleted --modified --others --exclude-standard` == ""
      end

      def commit_gemspec!
        gemspec_gitpath = working_subdir.join(gemspec_helper.path)
        repo.add(gemspec_gitpath.to_s)
        output.puts "Committing #{gemspec_gitpath}"
        repo.commit "Regenerate gemspec for version #{version}"
      end

      def regenerate_gemspec!
        gemspec_helper.update_version(version)
        gemspec_helper.write
      end

      def gemspec_changed?
        # OMGHAX. ruby-git status always ends up being 'M', so let's do it a crazy way
        system "git status -s #{working_subdir.join(gemspec_helper.path)} | grep  #{working_subdir.join(gemspec_helper.path)} > /dev/null 2>/dev/null"
      end

      def gemspec_helper
        @gemspec_helper ||= Juwelier::GemSpecHelper.new(self.gemspec, self.base_dir)
      end

      def working_subdir
        return @working_subdir if @working_subdir
        cwd = base_dir_path
        @working_subdir = cwd.relative_path_from(Pathname.new(repo.dir.path))
        @working_subdir
      end

      def base_dir_path
        Pathname.new(base_dir).realpath
      end

      def self.build_for(juwelier)
        command = self.new

        command.base_dir = juwelier.base_dir
        command.gemspec = juwelier.gemspec
        command.version = juwelier.version
        command.repo = juwelier.repo
        command.output = juwelier.output
        command.gemspec_helper = juwelier.gemspec_helper

        command
      end
    end
  end
end
