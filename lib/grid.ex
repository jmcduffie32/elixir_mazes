defmodule Grid do
  defstruct type: :square, rows: 0, cols: 0, grid: %{}, links: %{}

  def new(rows, cols, type \\ :square) do
    %Grid{type: type, rows: rows, cols: cols, grid: %{}, links: %{}}
  end

  defp polar_col_count(grid, row) do
    grid.cols * 2 ** div(row, 2)
  end

  def prepare_grid(%Grid{type: :polar} = grid) do
    Map.put(
      grid,
      :grid,
      for(
        row <- 0..(grid.rows - 1),
        col <- 0..(grid.cols * 2 ** div(row, 2)) - 1,
        into: %{},
        do: {{row, col}, Cell.new(row, col)}
      )
    )
  end

  def prepare_grid(%Grid{} = grid) do
    Map.put(
      grid,
      :grid,
      for(
        row <- 0..(grid.rows - 1),
        col <- 0..(grid.cols - 1),
        into: %{},
        do: {{row, col}, Cell.new(row, col)}
      )
    )
  end

  def neighbors(%Grid{type: :polar} = grid, %{row: row, col: col}) do
    potential_neighbors = if rem(row, 2) == 0 do
      [
        {row - 1, div(col, 2)},
        {row + 1, col},
        {row, if col + 1 >= polar_col_count(grid, row) do 0 else col + 1 end},
        {row, if col - 1 < 0 do polar_col_count(grid, row) - 1 else col - 1 end}
      ]
    else
      [
        {row - 1, col},
        {row + 1, col * 2},
        {row + 1, col * 2 + 1},
        {row, if col + 1 >= polar_col_count(grid, row) do 0 else col + 1 end},
        {row, if col - 1 < 0 do polar_col_count(grid, row) - 1 else col - 1 end}
      ]
    end

    # filter potential neighbors to only include those that are within the grid
    Enum.filter(potential_neighbors, fn {r, c} -> Map.get(grid.grid, {r, c}) end)
  end

  def neighbors(grid, %{row: row, col: col}) do
    potential_neighbors = [
      {row - 1, col},
      {row, col + 1},
      {row + 1, col},
      {row, col - 1}
    ]

    # filter potential neighbors to only include those that are within the grid
    Enum.filter(potential_neighbors, fn {r, c} -> Map.get(grid.grid, {r, c}) end)
  end


  def north(grid, %{row: row, col: col}) do
    Map.get(grid.grid, {row - 1, col})
  end

  def south(grid, %{row: row, col: col}) do
    Map.get(grid.grid, {row + 1, col})
  end

  def east(grid, %{row: row, col: col}) do
    Map.get(grid.grid, {row, col + 1})
  end

  def west(grid, %{row: row, col: col}) do
    Map.get(grid.grid, {row, col - 1})
  end

  # polar grid directions
  def inward(grid, %{row: row, col: col}) do
    if rem(row, 2) == 0 do
      Map.get(
        grid.grid,
        {row - 1, div(col, 2)}
      )
    else
      Map.get(
        grid.grid,
        {row - 1, col}
      )
    end
  end

  def clockwise(grid, %{row: row, col: col}) do
    if col - 1 < 0 do
      Map.get(grid.grid, {row, polar_col_count(grid, row) - 1})
    else
      Map.get(grid.grid, {row, col - 1})
    end
  end

  def counter_clockwise(grid, %{row: row, col: col}) do
    if col + 1 >= polar_col_count(grid, row) do
      Map.get(grid.grid, {row, 0})
    else
      Map.get(grid.grid, {row, col + 1})
    end
  end

  def random_cell(grid) do
    row = :rand.uniform(grid.rows) - 1
    col = :rand.uniform(grid.cols) - 1
    Map.get(grid.grid, {row, col})
  end

  def link(grid, cell1, cell2) do
    grid.links
    |> put_in([{cell1, cell2}], true)
    |> put_in([{cell2, cell1}], true)
  end

  defp draw_straight_wall(grid, cell, x1, y1, x2, y2, dir_fn) do
    if Map.get(grid.links, {cell, dir_fn.(grid, cell)}) do
      ""
    else
      """
      <line x1="#{x1}" y1="#{y1}" x2="#{x2}" y2="#{y2}" stroke="black" stroke-width="1"/>
      """
    end
  end

  defp draw_arc_wall(grid, cell, x1, y1, r, x2, y2, dir_fn) do
    if Map.get(grid.links, {cell, dir_fn.(grid, cell)}) do
      ""
    else
      """
      <path d="M #{x1} #{y1} A #{r} #{r} 0 0 1 #{x2} #{y2}" stroke="black" stroke-width="1" fill="none"/>
      """
    end
  end

  defp label_cell(cell, label_x, label_y) do
    """
    <text x="#{label_x}" y="#{label_y}" font-family="Arial" font-size="10" text-anchor="middle" alignment-baseline="middle">#{cell.row},#{cell.col}</text>
    """
  end

  def svg(grid, cell_size \\ 10, file_name \\ "maze.svg")

  def svg(%Grid{type: :polar} = grid, cell_size, file_name) do
    width = grid.rows * cell_size * 2
    height = width

    polar_lines =
      for {{row, col}, cell} <- grid.grid do
        theta = 2 * :math.pi() / polar_col_count(grid, row)
        r1 = row * cell_size
        r2 = (row + 1) * cell_size

        x1 = r1 * :math.cos(theta * col) + width / 2 + 1
        y1 = r1 * :math.sin(theta * col) + height / 2 + 1

        x2 = r2 * :math.cos(theta * col) + width / 2 + 1
        y2 = r2 * :math.sin(theta * col) + height / 2 + 1

        x3 = r1 * :math.cos(theta * (col + 1)) + width / 2 + 1
        y3 = r1 * :math.sin(theta * (col + 1)) + height / 2 + 1

        x4 = r2 * :math.cos(theta * (col + 1)) + width / 2 + 1
        y4 = r2 * :math.sin(theta * (col + 1)) + height / 2 + 1

        label_x = ((r2 - r1) / 2 + r1) * :math.cos(theta * (col + 0.5)) + width / 2 + 1
        label_y = ((r2 - r1) / 2 + r1) * :math.sin(theta * (col + 0.5)) + height / 2 + 1

        [
          label_cell(cell, label_x, label_y),
          draw_straight_wall(
            grid,
            cell,
            x1,
            y1,
            x2,
            y2,
            &clockwise/2
          ),
          draw_straight_wall(
            grid,
            cell,
            x3,
            y3,
            x4,
            y4,
            &counter_clockwise/2
          ),
          draw_arc_wall(
            grid,
            cell,
            x1,
            y1,
            r1,
            x3,
            y3,
            &inward/2
          ),
        ]
      end

    svg_str = """
    <svg xmlns="http://www.w3.org/2000/svg" width="#{width + 2}" height="#{height + 2}">
      <circle cx="#{width / 2 + 1}" cy="#{height / 2 + 1}" r="#{width / 2}" stroke="black" fill="none"/>
      #{List.flatten(polar_lines) |> Enum.uniq() |> Enum.join("\n")}
    </svg>
    """

    File.write!(file_name, svg_str)

    svg_str
  end

  def svg(grid, cell_size, file_name) do
    grid_lines =
      for {{row, col}, cell} <- grid.grid do
        x1 = col * cell_size
        y1 = row * cell_size
        x2 = (col + 1) * cell_size
        y2 = (row + 1) * cell_size

        [
          draw_straight_wall(grid, cell, x1, y1, x2, y1, &north/2),
          draw_straight_wall(grid, cell, x2, y1, x2, y2, &east/2),
          draw_straight_wall(grid, cell, x1, y2, x2, y2, &south/2),
          draw_straight_wall(grid, cell, x1, y1, x1, y2, &west/2)
        ]
      end

    width = grid.rows * cell_size
    height = grid.cols * cell_size

    svg_str = """
    <svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="#{height}">
      <line x1="0" y1="0" x2="#{width}" y2="0" stroke="black" stroke-width="1"/>
      <line x1="0" y1="#{height}" x2="0" y2="#{height}" stroke="black" stroke-width="1"/>
      #{List.flatten(grid_lines) |> Enum.uniq() |> Enum.join("\n")}
      <line x1="0" y1="0" x2="0" y2="#{height}" stroke="black" stroke-width="1"/>
      <line x1="#{width}" y1="0" x2="#{width}" y2="#{height}" stroke="black" stroke-width="1"/>
    </svg>
    """

    File.write!(file_name, svg_str)
    svg_str
  end
end
