# Hack TempFile to let us get at the underlying File object as ruby
# does a half assed job of making TempFile act as a File
class Tempfile
  def file
    @tmpfile
  end
end
