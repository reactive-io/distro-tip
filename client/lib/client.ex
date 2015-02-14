require Logger

defmodule Client do
  defstruct name: nil, pid: nil

  @name :stack

  def connect do
    Node.connect(:"server@MacBook-Pro")
  end

  def subscribe(name) do
    pid = spawn(__MODULE__, :notify, [])

    send server, {:subscribe, name, pid}

    %Client{name: name, pid: pid}
  end

  def unsubscribe(%Client{name: name, pid: pid}) do
    send server, {:unsubscribe, name}
    send pid, :stop
  end

  def push(%Client{name: name}, item) do
    send server, {:push, name, item}
  end

  def pop(%Client{name: name}) do
    send server, {:pop, name}
  end

  def get(%Client{name: name}) do
    send server, {:get, name}
  end

  def notify do
    receive do
      {:notify, :push, name, item} ->
        Logger.info("#{name} gave: '#{item}'")
        notify
      {:notify, :pop, name, {from, item}} ->
        Logger.info("#{name} took: '#{item}' from: #{from}")
        notify
      {:notify, :get, stack} ->
        Logger.info("current stack: #{inspect(stack)}")
        notify
      {:notify, :empty} ->
        Logger.info("nothing left to pop")
        notify
      :stop ->
        Logger.info("stopping")
      _any ->
        notify
    end
  end

  defp server do
    :global.whereis_name(@name)
  end
end
