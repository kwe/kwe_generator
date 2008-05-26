class KweScaffoldGenerator < Rails::Generator::NamedBase
  default_options :skip_timestamps => false, :skip_migration => false

  attr_reader   :controller_name,
                :controller_class_path,
                :controller_file_path,
                :controller_class_nesting,
                :controller_class_nesting_depth,
                :controller_class_name,
                :controller_underscore_name,
                :controller_singular_name,
                :controller_plural_name
  alias_method  :controller_file_name,  :controller_underscore_name
  alias_method  :controller_table_name, :controller_plural_name

  def initialize(runtime_args, runtime_options = {})
    super

    @controller_name = @name.pluralize

    base_name, @controller_class_path, @controller_file_path, @controller_class_nesting, @controller_class_nesting_depth = extract_modules(@controller_name)
    @controller_class_name_without_nesting, @controller_underscore_name, @controller_plural_name = inflect_names(base_name)
    @controller_singular_name=base_name.singularize
    if @controller_class_nesting.empty?
      @controller_class_name = @controller_class_name_without_nesting
    else
      @controller_class_name = "#{@controller_class_nesting}::#{@controller_class_name_without_nesting}"
    end
  end

  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions(controller_class_path, "#{controller_class_name}Controller", "#{controller_class_name}Helper")
      m.class_collisions(class_path, "#{class_name}")

      # Controller, helper, views, and test directories.
      m.directory(File.join('app/models', class_path))
      m.directory(File.join('app/controllers', controller_class_path))
      m.directory(File.join('app/helpers', controller_class_path))
      m.directory(File.join('app/views', controller_class_path, controller_file_name))
      m.directory(File.join('app/views/layouts', controller_class_path))
      m.directory(File.join('test/functional', controller_class_path))
      m.directory(File.join('test/unit', class_path))

      for action in scaffold_views
        m.template(
          "view_#{action}.html.haml.erb",
          File.join('app/views', controller_class_path, controller_file_name, "#{action}.html.haml")
        )
      end

      # Layout and stylesheet.
      puts "Layout"
      m.template('layout.html.haml.erb', File.join('app/views/layouts', controller_class_path, "#{controller_file_name}.html.haml"))
      m.template('style.css', 'public/stylesheets/scaffold.css')

      m.dependency 'model', [name] + @args, :collision => :skip

      m.template(
        'controller.rb', File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb")
      )

      m.template('functional_test.rb', File.join('test/functional', controller_class_path, "#{controller_file_name}_controller_test.rb"))
      m.template('helper.rb',          File.join('app/helpers',     controller_class_path, "#{controller_file_name}_helper.rb"))

      m.route_resources controller_file_name
    end
  end

  protected
  def form_link_for(table_name, singular_name)
       if !@controller_name.split("/")[1].nil?
         return "[:#{@controller_class_nesting.downcase}, @#{singular_name.singularize}]"  
       else
         return "@#{singular_name.singularize}"
       end    
     end

     def path_for(singular, plural, txt)
       case txt
       when "show"
         return "#{table_name.singularize}_path(@#{singular_name.singularize})"
       when "edit"
         return "edit_#{table_name.singularize}_path(@#{singular_name.singularize})"
       when "destroy"
         return "#{table_name.singularize}_path(@#{singular_name.singularize}), :confirm => 'Are you sure?', :method => :delete"
       when "index"  
         return "#{table_name}_path"
       end  
     end
  
    # Override with your own usage banner.
    def banner
      "Usage: #{$0} kwescaffold ModelName [field:type, field:type]"
    end

    def add_options!(opt)
      opt.separator ''
      opt.separator 'Options:'
      opt.on("--skip-timestamps",
             "Don't add timestamps to the migration file for this model") { |v| options[:skip_timestamps] = v }
      opt.on("--skip-migration",
             "Don't generate a migration file for this model") { |v| options[:skip_migration] = v }
    end

    def scaffold_views
      %w[ new index edit show ]
    end

    def model_name
      class_name.demodulize
    end
end
