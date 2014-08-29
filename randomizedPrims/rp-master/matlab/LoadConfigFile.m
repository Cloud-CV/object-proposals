function config = LoadConfigFile(configFile)

if(configFile((end-2):end)=='xml')
  config = xml2struct(configFile);
  config=config.config;
elseif(configFile((end-2):end)=='mat')
  load(configFile);
  config=params;
else
  error(['The extension of the config files should be .xml or .mat']);
end
end
