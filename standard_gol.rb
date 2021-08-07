# "Standard" / "Traditional" implementation of Game of Life.
#
# This is not particularly pretty code, and it's very slow, but it's written to be
# simple to follow.

# "Board" helpers, mostly to deal with loading from files, and printing to screen.
#
# In "standard game of life", we're representing the board as an array of arrays, with
# each cell containing the strings "0" or "1"
class Board
  # Loads an input pattern of 0's and 1's to use as an initial board
  def self.load_pattern(filename)
    lines = IO.readlines(filename)
    lines.map(&:strip).map{|line| line.split("") }
  end

  # Given a board, return the board's width and height
  def self.board_size(board)
    {
      w: board.first.count,
      h: board.count
    }
  end

  # Given a board, print it to screen  with spaces and squares,
  # to make it look nice and understandable
  def self.print(board)
    puts "\e[H\e[2J" # Clear the screen
    board.
      map(&:join).
      map{|line| line.gsub("0", " ").gsub("1", "█") }.
      each {|line| puts line }
  end
end

# Game Logic
class GameOfLife
  # Count the live neighbours for a given cell in the board.
  def self.neighbour_count(board, y, x)
    count = 0
  
    (y-1..y+1).each do |ny|
      (x-1..x+1).each do |nx|
        next if ny < 0 || nx < 0 || board[ny].nil? || board[ny][nx].nil? # Deal with edges
        next if ny == y && nx == x # ignore the cell itself
        count += 1 if board[ny][nx] == "1"
      end
    end
  
    count
  end

  def self.game_loop(board)
    board_size = Board.board_size(board)

    while true
      Board.print(board)

      new_board = board.map{|line| line.clone }

      board_size[:h].times do |y|
        board_size[:w].times do |x|
          ncount = GameOfLife.neighbour_count(board, y, x)
          new_cell_alive = (ncount == 3 || ncount == 2 && board[y][x] == "1")
          new_board[y][x] = new_cell_alive ? "1" : "0"
        end
      end

      board = new_board
    end
  end
end

# Loading the board / bootstrapping
INPUT_FILENAME = "input_pattern.txt"
board = Board.load_pattern(INPUT_FILENAME)
GameOfLife.game_loop(board)
