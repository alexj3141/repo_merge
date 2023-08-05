[string]$path = Read-Host -Prompt "Enter the path for the directory you wish to clone into "
[string]$repo_to_merge_into = Read-Host -Prompt "Enter url for the repo you wish to merge into (must end with .git) "
cd $path
git clone $repo_to_merge_into
$repo_to_merge_into_name = $repo_to_merge_into.Substring($repo_to_merge_into.lastIndexOf("/") + 1, $repo_to_merge_into.Length - 4 - ($repo_to_merge_into.lastIndexOf("/") + 1))
cd $repo_to_merge_into_name
[string]$only_main = Read-Host -Prompt "Merge only the main branches? [yes/no]"
[string]$keep_branch_subtrees = "not_applicable"
[string]$merge_branches_first = "not_applicable"
if($only_main -ne "yes" -and $only_main -ne "no") {
    $only_main = "yes"
}
if($only_main -eq "yes")
{
    $merge_branches_first = Read-Host -Prompt "Merge branches into main before adding main branch as subtree? [yes/no]"
    if($merge_branches_first -ne "yes" -and $merge_branches_first -ne "no")
    {
        $merge_branches_first -eq "yes"
    }
}
else {
    $keep_branch_subtrees = Read-Host -Prompt "Keep the branch subtree folders? [yes/no]"
    if($keep_branch_subtrees -ne "yes" -and $keep_branch_subtrees -ne "no")
    {
        $keep_branch_subtrees -eq "yes"
    }
}

[string[]]$repos_to_merge = @()
[string[]]$main_branch_names = @()
[int]$num_repos_to_merge = Read-Host -Prompt "How many repos would you like to merge?"

for([int]$i = 0; $i -lt $num_repos_to_merge; $i += 1)
{
    $repos_to_merge += (Read-Host -Prompt "Enter the $i th repo url (must end with .git) ")
    $main_branch_names += (Read-Host -Prompt "What is that repo's main branch name?")
    [string]$curr_repo_name = $repos_to_merge[$i].Substring($repos_to_merge[$i].lastIndexOf("/") + 1, $repos_to_merge[$i].Length - 4 - ($repos_to_merge[$i].lastIndexOf("/") + 1))
    [string]$curr_repo_origin_name = $curr_repo_name + "_origin"
    git remote add -f $curr_repo_origin_name $repos_to_merge[$i]
    [string[]]$curr_rtbs = git branch -r
    for([int]$j = 0; $j -lt $curr_rtbs.Length; $j += 1) {
        $curr_rtbs[$j] = $curr_rtbs[$j].Trim()
    }
    #[string[]]$curr_repo_rtbs = $curr_rtbs.Where($_.IndexOf($curr_repo_origin_name) -eq 0)
    [string[]]$curr_repo_rtbs = @()
    for([int]$j = 1; $j -lt $curr_rtbs.length; $j += 1) {
        if($curr_rtbs[$j].IndexOf($curr_repo_origin_name) -eq 0)
        {
            $curr_repo_rtbs += $curr_rtbs[$j]
        }
    }
    [string[]]$curr_repo_branch_names = @()
    [int]$curr_main_branch_index = 0
    for([int]$j = 0; $j -lt $curr_repo_rtbs.Length; $j += 1)
    {
        $curr_repo_branch_names += $curr_repo_rtbs[$j].Substring($curr_repo_rtbs[$j].IndexOf("/") + 1, $curr_repo_rtbs[$j].Length - ($curr_repo_rtbs[$j].IndexOf("/") + 1))
        if($curr_repo_branch_names[$j] -eq $main_branch_names[$i])
        {
            $curr_main_branch_index = $j
        }
    }
    if($only_main -eq "yes")
    {
        if($merge_branches_first -eq "yes")
        {
            cd ..
            git clone $repos_to_merge[$i]
            cd $curr_repo_name
            [string[]]$curr_repo_local_branches = git branch -r
            for([int]$j = 0; $j -lt $curr_repo_local_branches.Length; $j += 1) {
                $curr_repo_local_branches[$j] = $curr_repo_local_branches[$j].Trim()
            }
            for([int]$j = 1; $j -lt $curr_repo_local_branches.Length; $j += 1) {
                if($curr_repo_local_branches[$j].Substring($curr_repo_local_branches[$j].IndexOf("/") + 1, $curr_repo_local_branches[$j].Length - ($curr_repo_local_branches[$j].IndexOf("/") + 1)) -ne $main_branch_names[$i]) {
                    git merge -X ours $curr_repo_local_branches[$j] -m "merged $curr_repo_local_branches[$j] into branch $main_branch_names[$i]"
                }
            }
            git push
            cd ..
            cd $repo_to_merge_into_name
            git fetch $curr_repo_origin_name
            git subtree add -P $curr_repo_name $curr_repo_rtbs[$curr_main_branch_index]
        }
        else {
            git subtree add -P $curr_repo_name $curr_repo_rtbs[$curr_main_branch_index]
        }
    }
    else {
        if($keep_branch_subtrees -eq "yes")
        {

        }
        else {
            
        } 
    }
}
git push -u origin
