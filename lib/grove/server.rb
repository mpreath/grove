# frozen_string_literal: true

require "webrick"

module Grove
  module Server
    PORT = 4000

    def self.start(site_dir, builder: nil)
      output_dir = File.join(site_dir, "output")
      abort "Grove: output/ directory not found — run `grove build` first" unless Dir.exist?(output_dir)

      server = WEBrick::HTTPServer.new(
        Port:         PORT,
        DocumentRoot: output_dir,
        AccessLog:    [],
        Logger:       WEBrick::Log.new(File::NULL)
      )

      if builder
        watcher = Thread.new { watch(site_dir, builder) }
        watcher.abort_on_exception = false
      end

      puts "Grove: serving at http://localhost:#{PORT}  (Ctrl-C to stop)"
      trap("INT")  { server.shutdown }
      trap("TERM") { server.shutdown }
      server.start
    end

    # Poll the source directories once per second and trigger a rebuild whenever
    # any file's mtime advances.  Runs in a background thread started by +start+.
    def self.watch(site_dir, builder)
      last = latest_mtime(site_dir)
      loop do
        sleep 1
        current = latest_mtime(site_dir)
        if current > last
          last = current
          puts "\nGrove: change detected, rebuilding..."
          begin
            builder.build
            puts "Grove: done"
          rescue => e
            warn "Grove: build error — #{e.message}"
          end
        end
      end
    end

    # Returns the most-recent mtime among all watched source files.
    def self.latest_mtime(site_dir)
      candidates = [
        File.join(site_dir, "config.toml"),
        File.join(site_dir, "content"),
        File.join(site_dir, "templates"),
        File.join(site_dir, "static"),
      ]

      mtimes = candidates.flat_map do |path|
        if File.file?(path)
          [File.mtime(path)]
        elsif Dir.exist?(path)
          Dir.glob(File.join(path, "**", "*"))
             .select { |f| File.file?(f) }
             .map    { |f| File.mtime(f) }
        else
          []
        end
      end

      mtimes.max || Time.at(0)
    end

    private_class_method :watch, :latest_mtime
  end
end
