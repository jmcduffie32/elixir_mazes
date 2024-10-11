defmodule Prim do

  def on(grid) do
    active = [Grid.random_cell(grid)]
    step(grid, active)
  end

  defp has_links?(grid, cell) do
    grid.links
    |> Enum.map(fn {{k, _}, _} -> k end)
    |> MapSet.new()
    |> MapSet.member?(cell)
  end

  defp step(grid, []) do
    {grid, []}
  end

  defp step(grid, queue) do
    [current | rest] = queue

    unvisited =
      grid
      |> Grid.neighbors(current)
      |> Enum.map(fn x -> Map.get(grid.grid, x) end)
      |> Enum.filter(fn x -> !has_links?(grid, x) end)

    if unvisited != [] do
      index = :rand.uniform(Enum.count(unvisited)) - 1
      next = Enum.at(unvisited, index)
      step(Grid.link(grid, current, next), queue ++ [next])
    else
      step(grid, rest)
    end
  end
end
