defmodule Exterval do
  @moduledoc ~S"""
  Real-valued intervals with support for the `Enumerable` protocol.

  ## Installation

  The package can be installed
  by adding `exterval` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
  [
    {:exterval, "~> 0.2"}
  ]
  end
  ```

  ## Creation

  The entry point for creating an interval is the `~i` sigil:

  ```elixir
  iex> import Exterval
  iex> ~i<(1, 10]>
  (1.0,10.0]
  ```

  Intervals are represented as a struct with the following fields:

  * `left` - the left bracket, either `[` or `(`.
  * `right` - the right bracket, either `]` or `)`.
  * `min` - the lower bound of the interval. Can be `:neg_infinity` or any number.
  * `max` - the upper bound of the interval. Can be `:infinity` or any number.
  * `step` - the step size of the interval. If `nil`, the interval is continuous.

  The minimum value must be less than or equal to the maximum value.

  You may optionally specify a step size. The step size can be any real number.

  ```elixir
  iex> import Exterval
  iex> ~i<[1, 10)//2>
  [1, 10)//2
  iex> ~i<[1, 10)//2> |> Enum.to_list()
  [1.0, 3.0, 5.0, 7.0, 9.0]
  iex> ~i<[1, 10)//2> |> Enum.reduce(&+/2)
  25.0
  iex> ~i<[-1, 3)//-0.5> |> Enum.to_list()
  [2.5, 2.0, 1.5, 1.0, 0.5, 0.0, -0.5, -1.0]
  ```

  You can substitute variables into an interval using string interpolation, since the contents of the interval are just strings.

  ```elixir
  iex> import Exterval
  iex> min = 1
  iex> max = 10
  iex> step = 2
  iex> ~i<[#{min}, #{max})//#{step}>
  [1.0,10.0)//2.0
  ```

  ## Size

  You can use `Enum.count/1` to get the number of elements in the interval.

  If the interval is continuous, or either bound is an infinite bound, returns `:infinity`.
  If a step size is specified, returns the number of elements in the interval, rounded down to the nearest integer.
  If the interval is empty, returns `0`.

  ```elixir
  iex> import Exterval
  iex> ~i<[1, 10]> |> Enum.count()
  :infinity
  iex> ~i<[1, 10)//2> |> Enum.count()
  4
  iex> ~i<[-2,-2]//1.0> |> Enum.count()
  1
  iex> ~i<[1,2]//0.5> |> Enum.count()
  3
  iex> ~i<[-2,-1]//0.75> |> Enum.count()
  2
  iex> ~i<[1,2]//-0.5> |> Enum.count
  3
  ```

  ## Membership

  You can check a values membership in an interval using the normal reserving operator `in` or `Enum.member?/2`.

  ```elixir
  iex> import Exterval
  iex> 1 in ~i<[1, 10]>
  true
  iex> 1 in ~i<[1, 10)//2>
  true
  iex> 3 in ~i<(1, 10)//2>
  true
  ```

  You can also check if an interval is a subset of another interval using `in` or `Enum.member?/2`.

  Sub-interval must satisfy the following to be a subset:

  * The minimum value of the subset must belong to the superset.
  * The maximum value of the subset must belong to the superset.
  * The step size of the subset must be a multiple of the step size of the superset.

  If the superset has no step size, then only the first two conditions must be satisfied.

  if the superset has a step size, and the subset doesn't then membership is `false`.

  ## Enumeration

  You can only enumerate over an interval if it has a step size. You will be able to enumerate over the interval using the `Enumerable` protocol
  and all reduce-powered functions. If you do not specify a step size, the interval will be considered continuous and you will not be able to enumerate over it.
  If either bound is an infinite bound, then you may enumerate indefinitely over the interval, but the size of the interval will be `:infinity` and
  the reduction will never terminate. This may be useful for creating infinite sequences or with.

  If the step size is positive, the interval will be enumerated from the minimum value to the maximum value.
  If the step size is negative, the interval will be enumerated from the maximum value to the minimum value.


  Bear in mind that the more precise the step size, the more elements will be enumerated over even within the same
  upper and lower bounds, and the longer the reduction will take.  Additionally, the more precise the step size, the more
  likely it is that the reduction will not terminate due to floating point precision errors.
  """
  defstruct [:left, :right, :min, :max, :step]

  @type t :: %__MODULE__{
          left: String.t(),
          right: String.t(),
          min: number() | :neg_infinity,
          max: number() | :infinity,
          step: number() | nil
        }

  defmodule Infinity do
    @moduledoc false
    def reduce(%Exterval{}, _, _), do: {:halt, :infinity}
  end

  def sigil_i(pattern, []) do
    matches =
      Regex.named_captures(
        ~r/^(?P<left>\[|\()\s*(?P<min>[-+]?(?:\d+|\d+\.\d+)(?:[eE][-+]?\d+)?|:neg_infinity)\s*,\s*(?P<max>[-+]?(?:\d+|\d+\.\d+)(?:[eE][-+]?\d+)?|:infinity)\s*(?P<right>]|\))(?:\/\/(?P<step>[-+]?(?:[1-9]+|\d+\.\d+)(?:[eE][-+]?\d+)?))?$/,
        pattern,
        capture: :all_but_first
      )

    if is_nil(matches), do: raise(ArgumentError, "Invalid range specification")

    min =
      case Map.fetch!(matches, "min") do
        ":infinity" ->
          :infinity

        ":neg_infinity" ->
          :neg_infinity

        other ->
          {min, _rest} = Float.parse(other)
          min
      end

    max =
      case Map.fetch!(matches, "max") do
        ":infinity" ->
          :infinity

        ":neg_infinity" ->
          :neg_infinity

        other ->
          {max, _rest} = Float.parse(other)
          max
      end

    if is_number(min) and is_number(max) and max < min do
      raise "Exterval upper limit must be greater than or equal to lower limit. If you wish to enumerate over the interval starting from the upper limit, use a negative step size."
    end

    step =
      unless "" == Map.fetch!(matches, "step") do
        {step, _rest} = Map.get(matches, "step") |> Float.parse()
        if step == 0, do: raise("Step cannot be zero")
        step
      else
        nil
      end

    struct(__MODULE__,
      left: Map.fetch!(matches, "left"),
      right: Map.fetch!(matches, "right"),
      min: min,
      max: max,
      step: step
    )
  end

  @doc """
  Returns the number of elements in the interval.

  If the interval is continuous, or either bound is an infinite bound, returns `:infinity`.

  If a step size is specified, returns the number of elements in the interval, rounded down to the nearest integer.

  If the interval is empty, returns `0`.
  """
  @spec size(Exterval.t()) :: {:ok, non_neg_integer() | :infinity}
  def size(interval)
  def size(%__MODULE__{step: nil}), do: {:error, Infinity}
  def size(%__MODULE__{max: :neg_infinity}), do: 0
  def size(%__MODULE__{min: :infinity}), do: 0

  def size(%__MODULE__{min: min, max: max})
      when min in [:infinity, :neg_infinity] or max in [:infinity, :neg_infinity],
      do: {:error, Infinity}

  def size(%__MODULE__{left: left, right: right, min: min, max: max, step: step}) when step < 0 do
    case {left, right} do
      {"[", "]"} ->
        abs(trunc((max - min) / step)) + 1

      {"(", "]"} ->
        abs(trunc((max - (min - step)) / step)) + 1

      {"[", ")"} ->
        abs(trunc((max + step - min) / step)) + 1

      {"(", ")"} ->
        abs(trunc((max + step - (min - step)) / step)) + 1
    end
  end

  def size(%__MODULE__{left: left, right: right, min: min, max: max, step: step}) when step > 0 do
    case {left, right} do
      {"[", "]"} ->
        abs(trunc((max - min) / step)) + 1

      {"(", "]"} ->
        abs(trunc((max - (min + step)) / step)) + 1

      {"[", ")"} ->
        abs(trunc((max - step - min) / step)) + 1

      {"(", ")"} ->
        abs(trunc((max - step - (min + step)) / step)) + 1
    end
  end

  defimpl Inspect do
    import Inspect.Algebra
    import Kernel, except: [inspect: 2]

    def inspect(%Exterval{left: left, right: right, min: min, max: max, step: nil}, opts) do
      concat([string(left), to_doc(min, opts), ",", to_doc(max, opts), string(right)])
    end

    def inspect(%Exterval{left: left, right: right, min: min, max: max, step: step}, opts) do
      concat([
        string(left),
        to_doc(min, opts),
        ",",
        to_doc(max, opts),
        string(right),
        "//",
        to_doc(step, opts)
      ])
    end
  end

  defimpl Enumerable do
    def reduce(%Exterval{step: nil}, acc, _fun) do
      {:done, acc}
    end

    def reduce(%Exterval{left: left, right: right, min: min, max: max, step: step}, acc, fun)
        when step > 0 do
      case left do
        "[" ->
          reduce(min, max, right, acc, fun, step)

        "(" ->
          reduce(min + step, max, right, acc, fun, step)
      end
    end

    def reduce(%Exterval{left: left, right: right, min: min, max: max, step: step}, acc, fun)
        when step < 0 do
      case right do
        "]" ->
          reduce(min, max, left, acc, fun, step)

        ")" ->
          reduce(min, max + step, left, acc, fun, step)
      end
    end

    defp reduce(_min, _max, _right, {:halt, acc}, _fun, _step) do
      {:halted, acc}
    end

    defp reduce(min, max, right, {:suspend, acc}, fun, step) do
      {:suspended, acc, &reduce(min, max, right, &1, fun, step)}
    end

    defp reduce(:neg_infinity, _max, _right, {:cont, acc}, _fun, step) when step > 0 do
      {:done, acc}
    end

    defp reduce(_min, :infinity, _right, {:cont, acc}, _fun, step) when step < 0 do
      {:done, acc}
    end

    defp reduce(min, :infinity = max, right, {:cont, acc}, fun, step) do
      reduce(min + step, max, right, fun.(min, acc), fun, step)
    end

    defp reduce(:neg_infinity = min, max, right, {:cont, acc}, fun, step) do
      reduce(min + step, max, right, fun.(min, acc), fun, step)
    end

    defp reduce(min, max, "]" = right, {:cont, acc}, fun, step)
         when min <= max do
      reduce(min + step, max, right, fun.(min, acc), fun, step)
    end

    defp reduce(min, max, ")" = right, {:cont, acc}, fun, step)
         when min < max do
      reduce(min + step, max, right, fun.(min, acc), fun, step)
    end

    defp reduce(min, max, "[" = right, {:cont, acc}, fun, step)
         when min <= max do
      reduce(min, max + step, right, fun.(max, acc), fun, step)
    end

    defp reduce(min, max, "(" = right, {:cont, acc}, fun, step)
         when min < max do
      reduce(min, max + step, right, fun.(max, acc), fun, step)
    end

    defp reduce(_, _, _, {:cont, acc}, _fun, _up) do
      {:done, acc}
    end

    def count(interval) do
      case Exterval.size(interval) do
        {:error, mod} ->
          {:error, mod}

        other when is_number(other) ->
          {:ok, other}
      end
    end

    def slice(_enum), do: {:error, __MODULE__}

    def member?(%Exterval{step: nil} = outer, %Exterval{} = inner) do
      res = inner.max in outer && inner.min in outer
      {:ok, res}
    end

    def member?(%Exterval{}, %Exterval{step: nil}) do
      {:ok, false}
    end

    def member?(%Exterval{} = outer, %Exterval{} = inner) do
      res = inner.max in outer && inner.min in outer && :math.fmod(inner.step, outer.step) == 0
      {:ok, res}
    end

    def member?(%Exterval{} = rang, value) when is_number(value) do
      res =
        if Exterval.size(rang) == 0 do
          {:ok, false}
        else
          case {rang.left, rang.min, rang.max, rang.right} do
            {_, :neg_infinity, :infinity, _} ->
              true

            {_, :neg_inf, max_val, "]"} ->
              value <= max_val

            {_, :neg_infinity, max_val, ")"} ->
              value < max_val

            {"[", min_val, :infinity, _} ->
              value >= min_val

            {"(", min_val, :infinity, _} ->
              value > min_val

            {"[", min_val, max_val, "]"} ->
              value >= min_val and value <= max_val

            {"(", min_val, max_val, "]"} ->
              value > min_val and value <= max_val

            {"[", min_val, max_val, ")"} ->
              value >= min_val and value < max_val

            {"(", min_val, max_val, ")"} ->
              value > min_val and value < max_val

            _ ->
              raise ArgumentError, "Invalid range specification"
          end
        end

      res =
        unless is_nil(rang.step) || rang.min == :neg_infinity || rang.max == :infinity do
          res && :math.fmod(value - rang.min, rang.step) == 0
        else
          res
        end

      {:ok, res}
    end
  end
end
