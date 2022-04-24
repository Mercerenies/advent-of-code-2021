
const fs = require('fs');

enum Cell {
  EMPTY, EAST, SOUTH,
}

interface HasDims {
  readonly width: number;
  readonly height: number;
}

interface TargetRule {
  (dims: HasDims, y: number, x: number): [number, number];
}

function eastTargetRule(dims: HasDims, y: number, x: number): [number, number] {
  return [y, (x + 1) % dims.width];
}

function southTargetRule(dims: HasDims, y: number, x: number): [number, number] {
  return [(y + 1) % dims.height, x];
}

class Grid implements HasDims {
  private _grid: Cell[][];

  constructor(grid: Cell[][]) {
    this._grid = grid;
  }

  static fromLines(lines: string[]): Grid {
    const grid: Cell[][] = [];
    for (let y = 0; y < lines.length; y++) {
      const row: Cell[] = [];
      for (let x = 0; x < lines[y].length; x++) {
        let cell = Cell.EMPTY;
        switch (lines[y][x]) {
        case '>':
          cell = Cell.EAST;
          break;
        case 'v':
          cell = Cell.SOUTH;
          break;
        }
        row.push(cell);
      }
      grid.push(row);
    }
    return new Grid(grid);
  }

  toString(): string {
    let result = "";
    for (let y = 0; y < this.height; y++) {
      for (let x = 0; x < this.width; x++) {
        let char = '.';
        if (this.getCell(y, x) == Cell.EAST) {
          char = '>';
        } else if (this.getCell(y, x) == Cell.SOUTH) {
          char = 'v';
        }
        result += char;
      }
      result += '\n';
    }
    return result;
  }

  get width(): number {
    return this._grid[0].length
  }

  get height(): number {
    return this._grid.length
  }

  getCell(y: number, x: number): Cell {
    return this._grid[y][x];
  }

  clone(): Grid {
    const newGrid: Cell[][] = [];
    for (const row of this._grid) {
      newGrid.push(row.slice());
    }
    return new Grid(newGrid);
  }

  // Returns whether anybody moved.
  moveCucumbers(cellType: Cell, targetRule: TargetRule): boolean {
    let movedAtAll: boolean = false;
    // Decide who is allowed to move.
    const movingGrid: boolean[][] = [];
    for (let y = 0; y < this.height; y++) {
      const row: boolean[] = [];
      for (let x = 0; x < this.width; x++) {
        let isMoving: boolean = false;
        if (this.getCell(y, x) == cellType) {
          let [newY, newX] = targetRule(this, y, x);
          isMoving = this.getCell(newY, newX) == Cell.EMPTY;
        } else {
          isMoving = false;
        }
        row.push(isMoving);
        movedAtAll = movedAtAll || isMoving;
      }
      movingGrid.push(row);
    }
    // Now move anyone who wants to move.
    for (let y = 0; y < this.height; y++) {
      for (let x = 0; x < this.width; x++) {
        if (movingGrid[y][x]) {
          let [newY, newX] = targetRule(this, y, x);
          this._grid[y][x] = Cell.EMPTY;
          this._grid[newY][newX] = cellType;
        }
      }
    }
    return movedAtAll;
  }

}

// Returns whether anybody moved.
function runOneTurn(grid: Grid): boolean {
  const eastMove = grid.moveCucumbers(Cell.EAST, eastTargetRule);
  const southMove = grid.moveCucumbers(Cell.SOUTH, southTargetRule);
  return eastMove || southMove;
}

function run(): void {
  let lines = fs.readFileSync('input.txt', 'utf8').split('\n');
  if (lines[lines.length-1] == '') {
    // Ignore blank line at end.
    lines = lines.slice(0, -1);
  }
  const grid = Grid.fromLines(lines);
  let turnNumber = 0;
  let moved = true;
  while (moved) {
    turnNumber++;
    moved = runOneTurn(grid);
  }
  console.log(turnNumber);
}

run();
