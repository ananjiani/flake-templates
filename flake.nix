{
  description = "Templates";

  outputs =
    { ... }:
    {
      python-uv = {
        path = ./python-uv;
        description = "Boilerplate for python uv projects";
      };
    };
}
