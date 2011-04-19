module AutoloadHelper
  def register_lookup_modules(mods)
    (@lookup_module_index ||= {}).update(mods)
  end

  def lookup_module(key)
    return if !@lookup_module_index
    const_get @lookup_module_index[key] || key
  end

  def autoload_all(prefix, options)
    options.each do |const_name, path|
      autoload const_name, File.join(prefix, path)
    end
  end

  # Loads each autoloaded constant.
  # If thread safety is a concern, wrap
  # this in a Mutex.
  def load_autoloaded_constants
    constants.each do |const|
      const_get(const) if autoload?(const)
    end
  end

  def all_loaded_constants
    constants.map { |c| const_get(c) }.
      select { |a| a.respond_to?(:loaded?) && a.loaded? }
  end
end

