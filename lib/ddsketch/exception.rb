
module DDSketch
#thrown when an argument is misspecified
class IllegalArgumentException < Exception
end


#thrown when trying to merge two sketches with different relative_accuracy
#     parameters
class UnequalSketchParametersException < Exception
end
end