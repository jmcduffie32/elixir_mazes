defmodule Cell do
  defstruct row: 0, col: 0

  def new(row, col) do
    %Cell{row: row, col: col}
  end
end
