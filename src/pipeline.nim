import python # TODO support python3
import os, strutils, sequtils, tables

const debug = true

type
  Path = tuple[module: string, function: string] # path to a function - defined by name of module and name of function in it
  Pipe = tuple[origin: string, modifiers: tuple[mWhere: string, mTo: string, mWith: string], destination: string, pipeType: Pipes] # pipe between 2 components - defined by origin component and destination component
  Pipes = enum
    pTransformer, pFilter

# compiles pipeline document at given path to python code
proc compile*(path: string): string =
  # get contents of file
  let contents: string = readFile(path)

  # (1) parse contents of file

  var
    paths: Table[string, Path] = initTable[string, Path]() # table mapping alias to path
    pipes: seq[Pipe] = @[] # pipes connecting components

  # get tokens from contents
  var 
    tokens: seq[string] = @[]
    token: string = ""
    index: int = 0

  # iterate through characters in contents and tokenize
  while index <= contents.len - 1:
    let character: string = $contents[index] # get character at current index

    # handle character being an end-of-token character
    if character.isNilOrWhitespace or character == "(" or character == "#":
      if token.strip().len > 0: 
        tokens.add(token.strip()) # add token to tokens if current character is an end-of-token-character
      token = ""

    # handle character being start of parameter declaration
    if character == "(":
      let parameterDeclaration: string = contents[index .. contents.find(')', index)] # get whole parameter declaration
      tokens.add(parameterDeclaration)
      index = contents.find(')', index) + 1 # move to end of parameter declaration
    # handle character being start of comment
    elif character == "#":
      index = contents.find(NewLines, index) + 1 # move to end of comment
    else:
      token &= character # otherwise, append character to token
      # the character is only appended if it's not the end of a token or the start of a parameter declaration
      index += 1 # move to next character

  # parse tokens to paths and pipes
  var tokenIndex: int = 0
  for token in tokens:
    case token:
    of "import":
      # parse import statement
      let
        newPathAlias: string = tokens[tokenIndex + 1 + 2] # alias of new path
        newPathModule: string = tokens[tokenIndex - 1] # module for new path
        newPathFunction: string = tokens[tokenIndex + 1] # function for new path
        newPath: Path = (module : newPathModule, function : newPathFunction) # new path

      # add new path to paths
      paths[newPathAlias] = newPath
    of "|>":
      # parse tranformer pipe statement
      let
        prevToken: string = tokens[tokenIndex - 1] # previous token from contents
        nextToken: string = tokens[tokenIndex + 1] # next token from contnets
        newPipeOrigin: string = prevToken # origin of new pipe
        newPipeDestination: string = nextToken # destination of new pipe

      # extract where, to, with modifiers
      var
        numModifiers: int = 0
        modifiers: tuple[mWhere: string, mTo: string, mWith: string] = (mWhere : "", mTo : "", mWith : "")

      if numModifiers == 0 and tokenIndex + 3 <= tokens.len - 1:
        numModifiers += 1 # increment number of modifiers 
        case tokens[tokenIndex + 2]:
        of "where": modifiers.mWhere = tokens[tokenIndex + 3]
        of "to": modifiers.mTo = tokens[tokenIndex + 3]
        of "with": modifiers.mWith = tokens[tokenIndex + 3]

      if numModifiers == 1 and tokenIndex + 5 <= tokens.len - 1:
        numModifiers += 1 # increment number of modifiers
        case tokens[tokenIndex + 4]:
        of "where": modifiers.mWhere = tokens[tokenIndex + 5]
        of "to": modifiers.mTo = tokens[tokenIndex + 5]
        of "with": modifiers.mWith = tokens[tokenIndex + 5]

      if numModifiers == 2 and tokenIndex + 7 <= tokens.len - 1:
        numModifiers += 1 # increment number of modifiers
        case tokens[tokenIndex + 6]:
        of "where": modifiers.mWhere = tokens[tokenIndex + 7]
        of "to": modifiers.mTo = tokens[tokenIndex + 7]
        of "with": modifiers.mWith = tokens[tokenIndex + 7]

      # add new pipe
      pipes.add((origin : newPipeOrigin, modifiers : modifiers, destination : newPipeDestination, pipeType : pTransformer))
    of "/>":
      # parse tranformer pipe statement
      let
        prevToken: string = tokens[tokenIndex - 1] # previous token from contents
        nextToken: string = tokens[tokenIndex + 1] # next token from contnets
        newPipeOrigin: string = prevToken # origin of new pipe
        newPipeDestination: string = nextToken # destination of new pipe

      # extract where, to, with modifiers
      var
        numModifiers: int = 0
        modifiers: tuple[mWhere: string, mTo: string, mWith: string] = (mWhere : "", mTo : "", mWith : "")

      if numModifiers == 0 and tokenIndex + 3 <= tokens.len - 1:
        numModifiers += 1 # increment number of modifiers 
        case tokens[tokenIndex + 2]:
        of "where": modifiers.mWhere = tokens[tokenIndex + 3]
        of "to": modifiers.mTo = tokens[tokenIndex + 3]
        of "with": modifiers.mWith = tokens[tokenIndex + 3]
        else: numModifiers -= 1 # undo increment

      if numModifiers == 1 and tokenIndex + 5 <= tokens.len - 1:
        numModifiers += 1 # increment number of modifiers
        case tokens[tokenIndex + 4]:
        of "where": modifiers.mWhere = tokens[tokenIndex + 5]
        of "to": modifiers.mTo = tokens[tokenIndex + 5]
        of "with": modifiers.mWith = tokens[tokenIndex + 5]
        else: numModifiers -= 1 # undo increment

      if numModifiers == 2 and tokenIndex + 7 <= tokens.len - 1:
        numModifiers += 1 # increment number of modifiers
        case tokens[tokenIndex + 6]:
        of "where": modifiers.mWhere = tokens[tokenIndex + 7]
        of "to": modifiers.mTo = tokens[tokenIndex + 7]
        of "with": modifiers.mWith = tokens[tokenIndex + 7]
        else: numModifiers -= 1 # undo increment

      # add new pipe
      pipes.add((origin : newPipeOrigin, modifiers : modifiers, destination : newPipeDestination, pipeType : pFilter))
    else:
      discard

    # update index
    tokenIndex += 1

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

  # define function to run generator
  let generatorName: string = pipes[0].origin

  code &= "def run_" & generatorName & "(stream, out_queue):\n"
  code &= "\tfor data in stream:\n"
  code &= "\t\tout_queue.put(data)\n"
  code &= "\tout_queue.put(PipeSentinel())\n"

  # define functions for process for each component
  var componentIndex: int = 0
  for pipe in pipes:
    let 
      component: string = pipe.destination # destination of pipe ~ the component to define a function for
      modifiers: tuple[mWhere: string, mTo: string, mWith: string] = pipe.modifiers # modifiers of pipe
      parameters: string = if modifiers.mWhere.len > 0: modifiers.mWhere.replace("*", "inp") else: "(inp)" # parameters of pipe
      inputs: string = if componentIndex > 0: pipes[componentIndex - 1].modifiers.mTo.replace("(", "").replace(")", "") else: "" # names of inputs into current compoent
      # TODO handle with modifier

    var componentCode: string = "" # code for running component

    # initialize to variables to None
    for to in modifiers.mTo.replace("(", "").replace(")", "").split(","):
      componentCode &= to.strip() & " = None\n"

    # loop indefinitely
    componentCode &= "while 1:\n"

    # block and get next element from in queue`
    componentCode &= "\tinp = in_queue.get()\n"

    # unpackaget tuple input and reate local variables to access inputs if necessary
    # this is only done when input is from a transformer pipe (filter pipes always have only one input)
    if inputs != "" and pipes[componentIndex - 1].pipeType == pTransformer:
      componentCode &= "\t" & inputs & " = inp\n"

    # TODO use unique sentinel value
    # check if element from in queue is sentinel value
    componentCode &= "\tif isinstance(inp, PipeSentinel):\n"
    # put sentinel value in queue to next component
    componentCode &= "\t\toutp = PipeSentinel()\n"

    case pipe.pipeType:
    of pTransformer:
      # get output from passing element into component if element is not sentinel
      componentCode &= "\tif not isinstance(inp, PipeSentinel):\n"
      componentCode &= "\t\toutp = " & component & parameters & "\n"
      # unpackage output and update to variables
      if modifiers.mTo.len > 0:
        componentCode &= "\t\t" & modifiers.mTo.replace("(", "").replace(")", "") & " = outp\n"
    of pFilter:
      # get output from passing element into component if element is not sentinel
      componentCode &= "\tif not isinstance(inp, PipeSentinel):\n"
      componentCode &= "\t\tresult = " & component & parameters & "\n"
      if modifiers.mTo.len > 0:
        componentCode &= "\t\t" & modifiers.mTo.replace("(", "").replace(")", "") & " = result\n" # unpackage output and update to variables
      if modifiers.mWith.len > 0:
        componentCode &= "\t\tif " & modifiers.mWith.replace("(", "").replace(")", "") & ":\n" # send input through filter  
      else:
        componentCode &= "\t\tif result:\n" # send input through filter
      componentCode &= "\t\t\toutp = inp\n" # pass on input as output
      componentCode &= "\t\telse:\n"
      componentCode &= "\t\t\tcontinue\n" # otherwise continue to next input

    # check if queue to next component exists
    componentCode &= "\tif out_queue is not None:\n"

    # put output into queue to next component if queue to next component exists
    componentCode &= "\t\tout_queue.put(outp)\n"

    # break if element from in queue is sentinel value
    componentCode &= "\tif isinstance(inp, PipeSentinel):\n"
    componentCode &= "\t\tbreak\n"

    # update index of component
    componentIndex += 1

    # append component code to code
    code &= "def run_" & component & "(in_queue, out_queue):\n" # function header
    componentCode.removeSuffix("\n") # remove last newline
    code &= componentCode.indent(1, "\t") & "\n" # indent and add newline

  # MAIN

  # get iterator over stream of data
  let iteratorModule: string = pipes[0].origin
  mainCode &= "data = " & iteratorModule & "()\n"

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
  mainCode &= "run_" & generatorName & "(data, in_" & pipes[0].destination & ")\n" 

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
  mainCode.removeSuffix("\n") # remove last newline
  code &= mainCode.indent(1, "\t") & "\n" # indent main code and add newline

  # return code
  result = code

  if debug:
    echo(code)
 
# runs pipeline document at given path
proc runFile*(path: string) =
  # get compiled Python code
  let code: cstring = compile(path)

  # initialize the Python interpreter
  initialize()

  # add directory containing .pipeline file to PYTHONPATH
  when defined windows:
    syssetpath($(getPath()) & ";" & path[0 .. path.rfind("/")])
  else:
    syssetpath($(getPath()) & ":" & path[0 .. path.rfind("/")])

  # run code
  discard runSimpleString(code)

  # finalize the Python interpreter
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