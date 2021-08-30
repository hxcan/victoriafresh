package com.stupidbeauty.victoriafresh;

import java.util.ArrayList;
import java.util.List;

class EntryListJsonMessage
{
    private List<String> entryList=new ArrayList<>(); //!<条目列表。

    /**
     * 加入结果中。
     * @param currentFilegetFileName The file name.
     */
    public void addEntry(String currentFilegetFileName)
{
    entryList.add(currentFilegetFileName);
} //public void addEntry(String currentFilegetFileName)

}
