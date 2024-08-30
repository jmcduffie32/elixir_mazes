defmodule Cell do
  defstruct row: 0, col: 0, over: true

  def new(row, col) do
    %Cell{row: row, col: col, over: true}
  end
end
