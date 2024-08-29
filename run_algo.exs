{grid, _} = Grid.new(8, 8, :polar)
 |> Grid.prepare_grid()
 |> RecursiveBacktracker.on()

Grid.svg(grid)
