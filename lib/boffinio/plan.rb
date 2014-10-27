module BoffinIO 
  class Plan < APIResource
    include BoffinIO::APIOperations::List
    include BoffinIO::APIOperations::Create
  
  end
end