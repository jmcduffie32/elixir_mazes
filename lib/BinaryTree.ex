defmodule BinaryTree do
  def on(grid) do
    Enum.reduce(grid.grid, grid, fn {_, cell}, acc ->
      neighbors = Enum.filter([Grid.north(acc, cell), Grid.east(acc, cell)], fn x -> x end)

      if neighbors != [] do
        index = :rand.uniform(Enum.count(neighbors))
        neighbor = Enum.at(neighbors, index - 1)
        %{acc| links: Grid.link(acc, cell, neighbor)}
      else
        acc
      end
    end)
  end
end
