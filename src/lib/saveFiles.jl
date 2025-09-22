function pathSeparator()::String
  separator = ""
  if (Sys.isunix() || Sys.isapple())
    separator = "/"
  end
  if Sys.iswindows()
    separator = "\\"
  end
  return separator
end

function initializeFolders()
  mkpath(homedir() * pathSeparator() * esymiaFolderName * pathSeparator() * meshFolderName)
  mkpath(homedir() * pathSeparator() * esymiaFolderName * pathSeparator() * gridsFolderName)
end

function getStorageFilePaths(filename::String)
  meshPath = homedir() * pathSeparator() * esymiaFolderName * pathSeparator() * meshFolderName * pathSeparator() * filename * ".json"
  gridsPath = homedir() * pathSeparator() * esymiaFolderName * pathSeparator() * gridsFolderName * pathSeparator() * filename * ".json"
  return meshPath, gridsPath
end

function getStorageFilePathsGZip(filename::String)
  meshPath = homedir() * pathSeparator() * esymiaFolderName * pathSeparator() * meshFolderName * pathSeparator() * filename * ".gz"
  gridsPath = homedir() * pathSeparator() * esymiaFolderName * pathSeparator() * gridsFolderName * pathSeparator() * filename * ".gz"
  return meshPath, gridsPath
end

function getStorageFilePathsGZipMeshAndPlainGrids(filename::String)
  meshPath = homedir() * pathSeparator() * esymiaFolderName * pathSeparator() * meshFolderName * pathSeparator() * filename * ".gz"
  gridsPath = homedir() * pathSeparator() * esymiaFolderName * pathSeparator() * gridsFolderName * pathSeparator() * filename * ".json"
  return meshPath, gridsPath
end

function saveMeshAndGrids(fileName::String, data::Dict)
  initializeFolders()
  (meshPath, gridsPath) = getStorageFilePaths(fileName)
  open(gridsPath, "w") do f
    write(f, JSON.json(data["grids"]))
  end
  open(meshPath, "w") do f
    write(f, JSON.json(data["mesh"]))
  end
  return meshPath, gridsPath
end

# function saveGZippedMeshAndGrids(fileName::String, data::Dict)
#   initializeFolders()
#   (meshPath, gridsPath) = getStorageFilePathsGZip(fileName)
#   fh = GZip.open(meshPath, "w")
#   write(fh, JSON.json(data["mesh"]))
#   close(fh)
#   fh2 = GZip.open(gridsPath, "w")
#   write(fh2, JSON.json(data["grids"]))
#   close(fh2)
#   return meshPath, gridsPath
# end

function saveGZippedMeshAndPlainGrids(fileName::String, data::Dict)
  initializeFolders()
  (meshPath, gridsPath) = getStorageFilePathsGZipMeshAndPlainGrids(fileName)
  fh = GZip.open(meshPath, "w")
  write(fh, JSON.json(data["mesh"]))
  close(fh)
  open(gridsPath, "w") do f
    write(f, JSON.json(data["grids"]))
  end
  return meshPath, gridsPath
end

function saveOnS3GZippedMeshAndGrids(fileName::String, data::Dict, aws_config, bucket_name)
  # initializeFolders()
  # (meshPath, gridsPath) = getStorageFilePathsGZipMeshAndPlainGrids(fileName)
  # fh = GZip.open(meshPath, "w")
  # write(fh, JSON.json(data["mesh"]))
  # close(fh)
  # open(gridsPath, "w") do f
  #   write(f, JSON.json(data["grids"]))
  # end
  mesh_id = fileName*"_mesh.json.gz"
  grids_id = fileName*"_grids.json.gz"
  if(s3_exists(aws_config, bucket_name, mesh_id))
    s3_delete(aws_config, bucket_name, mesh_id)
  end
  if(s3_exists(aws_config, bucket_name, grids_id))
    s3_delete(aws_config, bucket_name, grids_id)
  end
  upload_json_gz(aws_config, bucket_name, mesh_id, data["mesh"])
  upload_json_gz(aws_config, bucket_name, grids_id, data["grids"])
  return mesh_id, grids_id
end

function upload_json_gz(aws_config, bucket_name, file_name, data_to_save)
  dato_compresso = transcode(GzipCompressor, JSON.json(data_to_save))
  s3_put(aws_config, bucket_name, file_name, dato_compresso)
end

function download_json_gz(aws_config, bucket, key)
  response = s3_get(aws_config, bucket, key)
  content = transcode(GzipDecompressor, response)
  GZip.open(key*".tmp.gz", "w") do f
    write(f, content)
  end
  s = IOBuffer()
  file = gzopen(key*".tmp.gz")
  while !eof(file)
    write(s, readline(file))
  end
  close(file)
  Base.Filesystem.rm(key*".tmp.gz", force=true)
  data2 = String(take!(s))
  return JSON.parse(data2)
end