function force_require(file)
    package.loaded[file] = nil;
	return require(file);
end;