{
  description = "Templates";

  outputs =
    { ... }:
    {
      templates = {
        python-data = {
          path = ./python-data;
          description = "Boilerplate for python data projects";
        };
        python-uv= {
          path = ./python-uv;
          description = "Boilerplate for python uv projects";
        };
      };
    };
}
