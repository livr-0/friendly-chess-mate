# Author: Linh Vu.
# Student ID: 103519240. Swinburne University of Technology.
# Language: Ruby.
# Gems: gosu.
# Program description: This programs allows users to play a classic 8x8 chess game against each other. It will enforce the rules of chess, calculating legal moves, detecting check and checkmate and displaying appropriate messages. 
# Notes: The program does not detect stalemate and pawn is automatically promoted to a queen if pawn promotion is possible. 

require 'rubygems'
require 'gosu'
require './console.rb'
require './game.rb'

# Global settings

WINDOW_WIDTH = 512; WINDOW_HEIGHT = 512; FONT_HEIGHT = 20
module ZOrder; CONSOLE, BOARD, PIECES, UI = *0..3; end

class FriendlyChessMate < Gosu::Window

    def needs_cursor?; true; end

    def initialize
        super WINDOW_WIDTH, WINDOW_HEIGHT, false
        self.caption = "Friendly Chess Mate"
        @font = Gosu::Font.new(FONT_HEIGHT, {:name => 'Arial'})

        # If this variable is true, a game is being played. 

        @in_game = false

        # The program has a collection of menus.

        @menus = setup_menus()
        @menu = @menus[0]
    end

    def update
        
        # Console holds the current menu and the game (if there is one going on).

        console_manager()
    end

    def draw
        draw_console()
    end

    def button_down(id)
        case id
        when Gosu::MsLeft
            click_handler()
        end
    end

end

FriendlyChessMate.new.show