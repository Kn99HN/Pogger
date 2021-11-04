defmodule Validator do
  

  
  defp read_from_file(file) do
    file = get_file_path()
    path_id = get_path_id()
    if file != nil do
      full_fname = "#{file}/#{path_id}"
      {:ok, path} = File.read(full_fname)
      decoded_path = Jason.decode!(path)
      IO.puts("#{inspect(decoded_path)}")
    end
  end

  defp get_file_path do
    System.get_env("EXPECTATION_FILE")
  end
end
