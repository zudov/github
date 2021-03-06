{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}
-----------------------------------------------------------------------------
-- |
-- License     :  BSD-3-Clause
-- Maintainer  :  Oleg Grenrus <oleg.grenrus@iki.fi>
--
-- The Owner teams API as described on
-- <http://developer.github.com/v3/orgs/teams/>.
module GitHub.Endpoints.Organizations.Teams (
    teamsOf,
    teamsOf',
    teamsOfR,
    teamInfoFor,
    teamInfoFor',
    teamInfoForR,
    createTeamFor',
    createTeamForR,
    editTeam',
    editTeamR,
    deleteTeam',
    deleteTeamR,
    listTeamMembersR,
    teamMembershipInfoFor,
    teamMembershipInfoFor',
    teamMembershipInfoForR,
    addTeamMembershipFor',
    addTeamMembershipForR,
    deleteTeamMembershipFor',
    deleteTeamMembershipForR,
    listTeamsCurrent',
    listTeamsCurrentR,
    module GitHub.Data,
    ) where

import Prelude        ()
import Prelude.Compat

import Data.Aeson.Compat (encode)
import Data.Vector       (Vector)

import GitHub.Data
import GitHub.Request

-- | List teams.  List the teams of an Owner.
-- When authenticated, lists private teams visible to the authenticated user.
-- When unauthenticated, lists only public teams for an Owner.
--
-- > teamsOf' (Just $ OAuth "token") "thoughtbot"
teamsOf' :: Maybe Auth -> Name Organization -> IO (Either Error (Vector SimpleTeam))
teamsOf' auth org =
    executeRequestMaybe auth $ teamsOfR org Nothing

-- | List the public teams of an Owner.
--
-- > teamsOf "thoughtbot"
teamsOf :: Name Organization -> IO (Either Error (Vector SimpleTeam))
teamsOf = teamsOf' Nothing

-- | List teams.
-- See <https://developer.github.com/v3/orgs/teams/#list-teams>
teamsOfR :: Name Organization -> Maybe Count -> Request k (Vector SimpleTeam)
teamsOfR org = PagedQuery ["orgs", toPathPart org, "teams"] []

-- | The information for a single team, by team id.
-- | With authentication
--
-- > teamInfoFor' (Just $ OAuth "token") 1010101
teamInfoFor' :: Maybe Auth -> Id Team -> IO (Either Error Team)
teamInfoFor' auth tid =
    executeRequestMaybe auth $ teamInfoForR tid

-- | The information for a single team, by team id.
--
-- > teamInfoFor' (Just $ OAuth "token") 1010101
teamInfoFor :: Id Team -> IO (Either Error Team)
teamInfoFor = teamInfoFor' Nothing

-- | Query team.
-- See <https://developer.github.com/v3/orgs/teams/#get-team>
teamInfoForR  :: Id Team -> Request k Team
teamInfoForR tid =
    Query ["teams", toPathPart tid] []

-- | Create a team under an Owner
--
-- > createTeamFor' (OAuth "token") "Owner" (CreateTeam "newteamname" "some description" [] PermssionPull)
createTeamFor' :: Auth
               -> Name Organization
               -> CreateTeam
               -> IO (Either Error Team)
createTeamFor' auth org cteam =
    executeRequest auth $ createTeamForR org cteam

-- | Create team.
-- See <https://developer.github.com/v3/orgs/teams/#create-team>
createTeamForR :: Name Organization -> CreateTeam -> Request 'True Team
createTeamForR org cteam =
    Command Post ["orgs", toPathPart org, "teams"] (encode cteam)

-- | Edit a team, by id.
--
-- > editTeamFor'
editTeam' :: Auth
          -> Id Team
          -> EditTeam
          -> IO (Either Error Team)
editTeam' auth tid eteam =
    executeRequest auth $ editTeamR tid eteam

-- | Edit team.
-- See <https://developer.github.com/v3/orgs/teams/#edit-team>
editTeamR :: Id Team -> EditTeam -> Request 'True Team
editTeamR tid eteam =
    Command Patch ["teams", toPathPart tid] (encode eteam)

-- | Delete a team, by id.
--
-- > deleteTeam' (OAuth "token") 1010101
deleteTeam' :: Auth -> Id Team -> IO (Either Error ())
deleteTeam' auth tid =
    executeRequest auth $ deleteTeamR tid

-- | Delete team.
--
-- See <https://developer.github.com/v3/orgs/teams/#delete-team>
deleteTeamR :: Id Team -> Request 'True ()
deleteTeamR tid =
    Command Delete ["teams", toPathPart tid] mempty

-- List team members.
--
-- See <https://developer.github.com/v3/orgs/teams/#list-team-members>
listTeamMembersR :: Id Team -> TeamMemberRole -> Maybe Count -> Request 'True (Vector SimpleUser)
listTeamMembersR tid r = PagedQuery ["teams", toPathPart tid, "members"] [("role", Just r')]
  where
    r' = case r of
        TeamMemberRoleAll         -> "all"
        TeamMemberRoleMaintainer  -> "maintainer"
        TeamMemberRoleMember      -> "member"

-- | Retrieve team mebership information for a user.
-- | With authentication
--
-- > teamMembershipInfoFor' (Just $ OAuth "token") 1010101 "mburns"
teamMembershipInfoFor' :: Maybe Auth -> Id Team -> Name Owner -> IO (Either Error TeamMembership)
teamMembershipInfoFor' auth tid user =
    executeRequestMaybe auth $ teamMembershipInfoForR tid user

-- | Query team membership.
-- See <https://developer.github.com/v3/orgs/teams/#get-team-membership
teamMembershipInfoForR :: Id Team -> Name Owner -> Request k TeamMembership
teamMembershipInfoForR tid user =
    Query ["teams", toPathPart tid, "memberships", toPathPart user] []

-- | Retrieve team mebership information for a user.
--
-- > teamMembershipInfoFor 1010101 "mburns"
teamMembershipInfoFor :: Id Team -> Name Owner -> IO (Either Error TeamMembership)
teamMembershipInfoFor = teamMembershipInfoFor' Nothing

-- | Add (or invite) a member to a team.
--
-- > addTeamMembershipFor' (OAuth "token") 1010101 "mburns" RoleMember
addTeamMembershipFor' :: Auth -> Id Team -> Name Owner -> Role-> IO (Either Error TeamMembership)
addTeamMembershipFor' auth tid user role =
    executeRequest auth $ addTeamMembershipForR tid user role

-- | Add team membership.
-- See <https://developer.github.com/v3/orgs/teams/#add-team-membership>
addTeamMembershipForR :: Id Team -> Name Owner -> Role -> Request 'True TeamMembership
addTeamMembershipForR tid user role =
    Command Put ["teams", toPathPart tid, "memberships", toPathPart user] (encode $ CreateTeamMembership role)

-- | Delete a member of a team.
--
-- > deleteTeamMembershipFor' (OAuth "token") 1010101 "mburns"
deleteTeamMembershipFor' :: Auth -> Id Team -> Name Owner -> IO (Either Error ())
deleteTeamMembershipFor' auth tid user =
    executeRequest auth $ deleteTeamMembershipForR tid user

-- | Remove team membership.
-- See <https://developer.github.com/v3/orgs/teams/#remove-team-membership>
deleteTeamMembershipForR :: Id Team -> Name Owner -> Request 'True ()
deleteTeamMembershipForR tid user =
    Command Delete ["teams", toPathPart tid, "memberships", toPathPart user] mempty

-- | List teams for current authenticated user
--
-- > listTeamsCurrent' (OAuth "token")
listTeamsCurrent' :: Auth -> IO (Either Error (Vector Team))
listTeamsCurrent' auth = executeRequest auth $ listTeamsCurrentR Nothing

-- | List user teams.
-- See <https://developer.github.com/v3/orgs/teams/#list-user-teams>
listTeamsCurrentR :: Maybe Count -> Request 'True (Vector Team)
listTeamsCurrentR = PagedQuery ["user", "teams"] []
