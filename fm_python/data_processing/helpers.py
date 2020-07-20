from datetime import date

def blpstring(d: date) -> str:
    """
    :param d: a datetime date object
    :return: A string corresponding to the string yyyymmdd - the format that blpapi likes for ingesting dates
    """
    return d.strftime('%Y%m%d')