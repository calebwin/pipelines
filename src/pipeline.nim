import python # TODO support python3
import os, strutils, tables

type
  Path = tuple[module: string, function: string] # path to a function - defined by name of module and name of function in it
  Pipe = tuple[origin: string, destination: string] # pipe between 2 components - defined by origin component and destination component

# compiles pipeline document at given path to python code
proc compile*(path: string): string =
  # get contents of file
  let contents: string = readFile(path)

  # (1) parse contents of file

  var
    paths: Table[string, Path] = initTable[string, Path]() # table mapping alias to path
    pipes: seq[Pipe] = @[] # pipes connecting components

  # get tokens from contents
  let tokens: seq[string] = splitWhitespace(contents)

  # parse tokens to paths and pipes
  var index: int = 0
  for token in tokens:
    case token:
    of "from":
      # parse statement
      let
        nextToken: string = tokens[index + 1] # next token from contents
        newPathAlias: string = tokens[index - 1] # alias of new path
        newPathModule: string = nextToken[0 .. nextToken.rfind("/") - 1] # module for new path
        newPathFunction: string = nextToken[nextToken.rfind("/") + 1 .. nextToken.len - 1] # function for new path
        newPath: Path = (module : newPathModule, function : newPathFunction) # new path

      # add new path to paths
      paths[newPathAlias] = newPath
    of "|":
      # parse statement
      let
        prevToken: string = tokens[index - 1] # previous token from contents
        nextToken: string = tokens[index + 1] # next token from contnets
        newPipeOrigin: string = prevToken # origin of new pipe
        newPipeDestination: string = nextToken # destination of new pipe
        newPipe: Pipe = (origin : newPipeOrigin, destination : newPipeDestination)  # new pipe

      # add new pipe
      pipes.add(newPipe)
    else:
      discard

    # update index
    index += 1

  # (2) generate target code

  # initialize code with import statements
  var
    code: string = "from multiprocessing import Process, Queue\n"
    mainCode: string = ""

  # IMPORTS

  # import functions
  for alias, path in pairs(paths):
    code &= "from " & path.module & " import " & path.function & " as " & alias & "\n"

  # FUNCTIONS

  # define pipe sentinel
  code &= "class PipeSentinel: pass\n"

  # define functions for process for each component
  for pipe in pipes:
    let component: string = pipe.destination # destination of pipe ~ the component to define a function for

    var componentCode: string = "" # code for running component

    # loop indefinitely
    componentCode &= "while True:\n"

    # block and get next element from in queue
    componentCode &= "\tinput = in_queue.get()\n"

    # TODO use unique sentinel value
    # check if element from in queue is sentinel value
    componentCode &= "\tif isinstance(input, PipeSentinel):\n"

    # put sentinel value in queue to next component
    componentCode &= "\t\toutput = PipeSentinel()\n"

    # else
    componentCode &= "\telse:\n"

    # otherwise, get output from passing element into component
    componentCode &= "\t\toutput = " & component & "(input)\n"

    # check if queue to next component exists
    componentCode &= "\tif out_queue is not None:\n"

    # put output into queue to next component if queue to next component exists
    componentCode &= "\t\tout_queue.put(output)\n"

    # break if element from in queue is sentinel value
    componentCode &= "\tif isinstance(input, PipeSentinel):\n"
    componentCode &= "\t\tbreak\n"

    # append component code to code
    code &= "def run_" & component & "(in_queue, out_queue):\n"
    code &= componentCode.indent(1, "\t") & "\n"

  # MAIN

  # get iterator over stream of data
  let iteratorModule: string = pipes[0].origin
  mainCode &= "stream = " & iteratorModule & "()\n"

  # create queues into components
  for pipe in pipes:
    let component: string = pipe.destination # component to create a queue into

    # create queue into component
    mainCode &= "in_" & component & " = Queue()\n"

  # create processes for each component
  var pipeIndex: int = 0
  for pipe in pipes:
    let 
      component: string = pipes[pipeIndex].destination # component to create process for
      componentQueue: string = "in_" & component # queue to component to create process for
      nextComponentQueue: string = if pipeIndex < pipes.len - 1: "in_" & pipes[pipeIndex + 1].destination else: "None" # queue to next component in pipeline

    # creat process for component passing in queue to the component and queue to next component
    mainCode &= component & "_process = Process(target=run_" & component & ", args=(" & componentQueue  & ","  & nextComponentQueue & ",))\n"

    # update index in pipes
    pipeIndex += 1

  # load all data from generator into queue to first component
  mainCode &= "for data in stream:\n"
  mainCode &= "\tin_" & pipes[0].destination & ".put(data)\n"

  # load sentinel value into queue
  mainCode &= "in_" & pipes[0].destination & ".put(PipeSentinel())\n"

  # start processes
  for pipe in pipes:
    let component: string = pipe.destination # component to start process of

    # start process of component
    mainCode &= component & "_process.start()\n"

  # block main process till all process have finished
  for pipe in pipes:
    let component: string = pipe.destination # component to join process of

    # join process of component
    mainCode &= component & "_process.join()\n"

  # append main code to code
  code &= "if __name__ == \"__main__\":\n"
  code &= mainCode.indent(1, "\t") & "\n"

  # return code
  result = code

# runs pipeline document at given path
proc runFile*(path: string) =
  # TODO use lower-level API for python3 interpreter instead of code gen
  # compile pipeline document at given path
  let code: string = compile(path)

  # initialize the python interpreter
  initialize()

  # add directory containing .pipeline file to PYTHONPATH
  syssetpath($(getPath()) & ":" & path[0 .. path.rfind("/")])

  # execute python code
  let result: int = runSimpleString(code)

  # finalize python interpreter
  finalize()

# compiles pipeline document at given path to python file at same path with ,py file extension
proc compileFile*(path: string) =
  # compile pipeline document at given path
  let code: string = compile(path)

  # get path to new python file
  let targetPath: string = path.replace(".pipeline", ".py")

  # print code to file at target path
  writeFile(targetPath, code)

proc main() =
  case paramCount():
  of 0:
    # print welcome message
    echo("Welcome to Pipeline!")
    echo("v:0.0.1")
  of 1:
    # get path to file to run
    let path: string = paramStr(1)

    # run file
    runFile(path)
  of 2:
    case paramStr(1):
    of "r", "run":
      # get path to file to run
      let path: string = paramStr(2)

      # run file
      runFile(path)
    of "c", "compile":
      # get path to file to compile
      let path: string = paramStr(2)

      # compile file
      compileFile(path)
  else:
    discard

main()