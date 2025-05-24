class GetMenuReqParams {
  final String mensaName;

  GetMenuReqParams({
    required this.mensaName, 
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mensaName': mensaName,
    };
  }

}

