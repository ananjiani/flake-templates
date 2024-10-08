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

      default = python-data;
      };
    };
}
