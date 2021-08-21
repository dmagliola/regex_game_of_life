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
  def self.ascii_print(board)
    puts "\e[H\e[2J" # Clear the screen
    board.
      map(&:join).
      map{|line| line.gsub("0", " ").gsub("1", "█") }.
      each {|line| puts line }
  end

  def self.braille_print(board)
    puts "\e[H\e[2J" # Clear the screen

    board = board.map{|line| line.clone }

    # Make sure the board size is a multiple of 2 in width, and of 4 in height
    board.each{|line| line << "0" } unless board_size(board)[:w].even?
    board << Array.new(board_size(board)[:w], "0") while board_size(board)[:h] % 4 != 0

    while board.length > 0
      # print 4 lines at a time
      lines = board.shift(4)

      while lines.first.length > 0
        bits = lines.flat_map{|l| l.shift(2) }
        # Rearrange to account for the fact that we go 1,2,3,7,4,5,6,8 vertically (https://en.wikipedia.org/wiki/Braille_Patterns)
        bits = [7,6,5,3,1,4,2,0].map{|i| bits[i]}
        unicode = "2800".to_i(16) + bits.join("").to_i(2)
        print unicode.chr(Encoding::UTF_8)
      end

      puts ""
    end
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
      Board.ascii_print(board)
      # Board.braille_print(board)

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
