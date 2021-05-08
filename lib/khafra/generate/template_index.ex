defmodule Khafra.Generate.TemplateIndex do
  import Khafra.Generate.Template

  alias Khafra.Generate.GenerateFromConfig


  def get(args), do: get(args, %{})

  def get([{:type, :distributed}|args], map), do: get(args, Map.put(map, :type, "distributed"))

  def get([{:local, locals}|args], map), do: get(args, Map.put(map, :local, locals))

  def get([{:remote, locals}|args], map), do: get(args, Map.put(map, :remote, locals))
  
  def get([{:name, name}|args], map), do: get(args, Map.put(map, :name, name))

  def get([{:parent, parent_name}|args], map) do
    # Name guaranteed to be first, therefore safe:
    name = map.name

    get(args, Map.put(map, :index_name, "#{name} : #{parent_name}"))
  end

  def get([{:source, {:sql, source_name}}|args], map) do
    source = GenerateFromConfig.gen_sql_source(source_name)

    get(args, non_unique_arg(Map.put(map, :index_source, source), :args, :source, source_name))
  end

  def get([{:source, source_name}|args], map) do
    source = GenerateFromConfig.get_source(source_name)

    get(args, non_unique_arg(Map.put(map, :index_source, source), :args, :source, source_name))
  end

  def get([{key, arg}|args], map) do 
    arg = String.replace(arg, "[cwd!]", System.cwd())

    get(args, non_unique_arg(map, :args, key, arg))
  end

  def get([], %{:args => arg_list} = map) when is_list(arg_list) do
    get([], Map.replace!(map, :args, combine_non_unique_args(arg_list)))
  end

  def get([], %{:type => "distributed", :name => name} = map) do
    name = Atom.to_string(name)
    name_upper = String.upcase(name)

    local_indexes = Enum.map(Map.get(map, :local, []), fn local -> "local = #{Atom.to_string(local)}\n  " end)
    remote_indexes = Enum.map(Map.get(map, :remote, []), fn remote -> "remote = #{Atom.to_string(remote)}\n  " end)

    ~s"""
    ## #{name_upper}
    ####################################################
    index #{name}
    {
      type = distributed
      #{local_indexes}
      #{remote_indexes}
    }
    """
  end

  def get([], %{:name => name, :args => args, :index_source => source} = map) do
    path = File.cwd!() |> Path.join("sphinx/data/#{name}")
    path = "path = #{path}"

    name_upper = String.upcase(Atom.to_string(name))
    
    index_name = case map do
      %{index_name: index_name} -> index_name
      _ -> Atom.to_string(name)
    end

    ~s"""
    ## #{name_upper}
    ####################################################
    #{source}
    index #{index_name}
    {
      #{args}
      #{path}
    }
    """
  end
end