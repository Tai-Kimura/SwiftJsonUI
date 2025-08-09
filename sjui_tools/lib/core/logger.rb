# frozen_string_literal: true

module SjuiTools
  module Core
    class Logger
      LEVELS = {
        error: 0,
        warn: 1,
        info: 2,
        debug: 3
      }.freeze

      class << self
        attr_writer :level

        def level
          @level ||= :info
        end

        def set_level(level_name)
          level_sym = level_name.to_s.downcase.to_sym
          unless LEVELS.key?(level_sym)
            error "Invalid log level: #{level_name}. Using 'info' instead."
            @level = :info
          else
            @level = level_sym
          end
        end

        def error(message)
          puts colorize("ERROR: #{message}", :red)
        end

        def warn(message)
          puts colorize("WARNING: #{message}", :yellow) if should_log?(:warn)
        end

        def info(message)
          puts message if should_log?(:info)
        end

        def debug(message)
          puts colorize("DEBUG: #{message}", :gray) if should_log?(:debug)
        end

        def success(message)
          puts colorize("✓ #{message}", :green) if should_log?(:info)
        end

        private

        def should_log?(message_level)
          LEVELS[message_level] <= LEVELS[level]
        end

        def colorize(text, color)
          return text unless $stdout.tty?

          color_codes = {
            red: 31,
            green: 32,
            yellow: 33,
            blue: 34,
            gray: 90
          }

          code = color_codes[color] || 0
          "\e[#{code}m#{text}\e[0m"
        end
      end
    end
  end
end