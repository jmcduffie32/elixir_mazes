  defimpl Kino.Render, for: Grid do
    def to_livebook(grid) do
      {cell_size, inset } = if grid.type == :polar do
        {40, 0}
      else
        {20, 2}
      end
      svg_str = Grid.svg(grid, cell_size, inset)
      svg_kino = Kino.Image.new(svg_str, :svg)
      inspect_kino = Kino.Inspect.new(grid)
      kino = Kino.Layout.tabs(Maze: svg_kino, Raw: inspect_kino)
      Kino.Render.to_livebook(kino)
    end
  end
