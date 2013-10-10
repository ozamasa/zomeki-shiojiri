class Script
  cattr_reader :lock_key
  cattr_reader :options

  def self.run(path, options = nil)
    ENV['INPUTRC'] ||= '/etc/inputrc'

    @@lock_key = 'script_' + path.gsub(/\W/, '_')
    @@options  = options
    
    unless self.lock
      puts "[ #{Time.now.strftime('%Y-%m-%d %H:%M:%S')} ]: Script.run('#{path}') already running."
      return true
    end

    begin
      puts "[ #{Time.now.strftime('%Y-%m-%d %H:%M:%S')} ]: Script.run('#{path}') started."

      app = ActionController::Integration::Session.new(Rails.application)
      app.get "/_script/sys/run/#{path}"

      puts "[ #{Time.now.strftime('%Y-%m-%d %H:%M:%S')} ]: Script.run('#{path}') finished."
    rescue => e
      puts e.backtrace.join("\n") + "\n\n"
      puts "ScriptError: #{e}"
    end

    self.unlock
  end

  protected

  def self.lock(lock_key = @@lock_key)
    file = Rails.root.join("tmp/lock/#{lock_key}").to_s
    if ::File.exist?(file)
      locked = ::File.stat(file).mtime
      return false if Time.now < 1.day.since(locked)
      self.unlock(lock_key)
    end
    ::File.open(file, 'w').close
    return true
  rescue
    return false
  end

  def self.unlock(lock_key = @@lock_key)
    file = Rails.root.join("tmp/lock/#{lock_key}").to_s
    ::File.unlink(file)
  end

  def self.keep_lock(lock_key = @@lock_key)
    file = Rails.root.join("tmp/lock/#{lock_key}").to_s
    FileUtils.touch(file) rescue nil
  end
end
